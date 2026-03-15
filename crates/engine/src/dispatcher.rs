use std::sync::{Arc, Mutex};
use engine_api::{EngineCommand, EngineEvent, EngineError};
use engine_api::error::{EngineErrorCode, EngineResult};
use crate::state::EngineState;

/// Main command dispatcher — receives `EngineCommand`, mutates state, emits `EngineEvent`.
pub struct EngineDispatcher {
    state: Arc<Mutex<EngineState>>,
    event_tx: std::sync::mpsc::Sender<EngineEvent>,
}

impl EngineDispatcher {
    pub fn new(event_tx: std::sync::mpsc::Sender<EngineEvent>) -> Self {
        Self {
            state: Arc::new(Mutex::new(EngineState::default())),
            event_tx,
        }
    }

    /// Dispatch a command and return Ok or a structured EngineError.
    pub fn dispatch(&self, cmd: EngineCommand) -> EngineResult<()> {
        let mut state = self.state.lock().map_err(|_| {
            EngineError::new(EngineErrorCode::InternalError, "State lock poisoned")
        })?;

        match cmd {
            EngineCommand::CreateProject { name, resolution, frame_rate, color_profile, audio } => {
                use project_schema::{NovaProject, ProjectSettings};
                let settings = ProjectSettings {
                    resolution,
                    frame_rate,
                    color_profile,
                    audio,
                    ..ProjectSettings::default()
                };
                let project = NovaProject::new(name, settings);
                let project_id = project.project_id;
                state.project = Some(project);
                let _ = self.event_tx.send(EngineEvent::ProjectOpened {
                    project_id,
                    name: state.project.as_ref().unwrap().name.clone(),
                    path: String::new(),
                });
            }

            EngineCommand::OpenProject { path } => {
                use project_schema::io::ProjectIo;
                use project_schema::migration::MigrationRunner;
                let std_path = std::path::Path::new(&path);
                let mut project = ProjectIo::load(std_path).map_err(|e| {
                    EngineError::new(EngineErrorCode::ProjectLoadFailed, e.to_string())
                })?;
                if MigrationRunner::is_too_new(&project) {
                    return Err(EngineError::new(
                        EngineErrorCode::SchemaVersionMismatch,
                        "Project was created by a newer version of Nova Compositor",
                    ));
                }
                MigrationRunner::migrate(&mut project).map_err(|e| {
                    EngineError::new(EngineErrorCode::MigrationFailed, e.to_string())
                })?;
                let project_id = project.project_id;
                let name = project.name.clone();
                state.project = Some(project);
                state.project_path = Some(path.clone());
                let _ = self.event_tx.send(EngineEvent::ProjectOpened { project_id, name, path });
            }

            EngineCommand::SaveProject => {
                let project = state.project.as_ref().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                let path = state.project_path.as_ref().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectSaveFailed, "Project has no path; use SaveProjectAs")
                })?;
                use project_schema::io::ProjectIo;
                ProjectIo::save(project, std::path::Path::new(path)).map_err(|e| {
                    EngineError::new(EngineErrorCode::ProjectSaveFailed, e.to_string())
                })?;
                let _ = self.event_tx.send(EngineEvent::ProjectSaved { path: path.clone() });
            }

            EngineCommand::SaveProjectAs { path } => {
                let mut project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                project.touch();
                use project_schema::io::ProjectIo;
                ProjectIo::save(project, std::path::Path::new(&path)).map_err(|e| {
                    EngineError::new(EngineErrorCode::ProjectSaveFailed, e.to_string())
                })?;
                state.project_path = Some(path.clone());
                let _ = self.event_tx.send(EngineEvent::ProjectSaved { path });
            }

            EngineCommand::CloseProject => {
                state.project = None;
                state.project_path = None;
                let _ = self.event_tx.send(EngineEvent::ProjectClosed);
            }

            EngineCommand::AddComposition { name, resolution, frame_rate, duration, color_profile } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                use project_schema::Composition;
                let comp = Composition::new(name, resolution, frame_rate, duration);
                let comp_id = comp.id;
                let project_id = project.project_id;
                project.compositions.push(comp);
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::CreateSequence { name, resolution, frame_rate } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                use project_schema::Sequence;
                let mut seq = Sequence::new(name, resolution, frame_rate);
                
                // NLE Defaults: Add 3 Video and 3 Audio tracks
                use project_schema::{Track, TrackKind};
                seq.video_tracks.push(Track::new("V3", TrackKind::Video));
                seq.video_tracks.push(Track::new("V2", TrackKind::Video));
                seq.video_tracks.push(Track::new("V1", TrackKind::Video));
                
                seq.audio_tracks.push(Track::new("A1", TrackKind::Audio));
                seq.audio_tracks.push(Track::new("A2", TrackKind::Audio));
                seq.audio_tracks.push(Track::new("A3", TrackKind::Audio));

                let project_id = project.project_id;
                project.sequences.push(seq);
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::AddClipToSequence { sequence_id, track_index, asset_id, start_time } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;

                let asset = project.assets.iter().find(|a| a.id == asset_id).cloned().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::AssetLoadFailed, format!("Asset not found: {}", asset_id))
                })?;

                let seq = project.sequences.iter_mut().find(|s| s.id == sequence_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::InternalError, format!("Sequence not found: {}", sequence_id))
                })?;

                use project_schema::Clip;
                let duration = engine_api::types::RationalTime::new(300, 30); // MVP: 10 seconds
                let source_in = engine_api::types::RationalTime::new(0, 30);
                
                use project_schema::AssetKind;
                let mut audio_clip_opt = None;

                let clip = Clip::new_asset(
                    asset.name.clone(),
                    asset_id,
                    asset.kind.clone(),
                    start_time,
                    source_in,
                    duration,
                );
                
                if asset.kind == AssetKind::Video {
                    let mut audio_clip = clip.clone();
                    audio_clip.id = uuid::Uuid::new_v4(); // Generate unique ID for the linked audio clip
                    audio_clip_opt = Some(audio_clip);
                }

                if track_index < seq.video_tracks.len() {
                    seq.video_tracks[track_index].clips.push(clip);
                }
                
                if let Some(audio_clip) = audio_clip_opt {
                    if !seq.audio_tracks.is_empty() {
                        seq.audio_tracks[0].clips.push(audio_clip);
                    }
                }

                let project_id = project.project_id;
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::MoveClipInSequence { sequence_id, clip_id, new_track_index, new_start_time } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;

                let seq = project.sequences.iter_mut().find(|s| s.id == sequence_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::InternalError, format!("Sequence not found: {}", sequence_id))
                })?;

                // Find and remove the clip from whichever track it's currently in
                let mut found_clip = None;
                for track in &mut seq.video_tracks {
                    if let Some(idx) = track.clips.iter().position(|c| c.id == clip_id) {
                        found_clip = Some(track.clips.remove(idx));
                        break;
                    }
                }
                if found_clip.is_none() {
                    for track in &mut seq.audio_tracks {
                        if let Some(idx) = track.clips.iter().position(|c| c.id == clip_id) {
                            found_clip = Some(track.clips.remove(idx));
                            break;
                        }
                    }
                }

                let mut clip = found_clip.ok_or_else(|| {
                    EngineError::new(EngineErrorCode::InternalError, format!("Clip {} not found in Sequence {}", clip_id, sequence_id))
                })?;

                // Update start time
                clip.start_time = new_start_time;

                // Insert into new track
                // If the track is video vs audio, the UI should ideally pass the correct index.
                // We assume video index if < video_tracks.len, else audio index.
                if new_track_index < seq.video_tracks.len() {
                    seq.video_tracks[new_track_index].clips.push(clip);
                } else {
                    let audio_idx = new_track_index - seq.video_tracks.len();
                    if audio_idx < seq.audio_tracks.len() {
                        seq.audio_tracks[audio_idx].clips.push(clip);
                    } else {
                        // Truncate fallback to last track
                        if !seq.audio_tracks.is_empty() {
                            let last = seq.audio_tracks.len() - 1;
                            seq.audio_tracks[last].clips.push(clip);
                        }
                    }
                }

                let project_id = project.project_id;
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::RemoveClipFromSequence { sequence_id, clip_id } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;

                let seq = project.sequences.iter_mut().find(|s| s.id == sequence_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::InternalError, format!("Sequence not found: {}", sequence_id))
                })?;

                let mut removed = false;
                for track in seq.video_tracks.iter_mut().chain(seq.audio_tracks.iter_mut()) {
                    if let Some(idx) = track.clips.iter().position(|c| c.id == clip_id) {
                        track.clips.remove(idx);
                        removed = true;
                        break;
                    }
                }

                if !removed {
                    return Err(EngineError::new(
                        EngineErrorCode::InternalError,
                        format!("Clip {} not found in Sequence {}", clip_id, sequence_id),
                    ));
                }

                let project_id = project.project_id;
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::SplitClipInSequence { sequence_id, clip_id, split_time } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;

                let seq = project.sequences.iter_mut().find(|s| s.id == sequence_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::InternalError, format!("Sequence not found: {}", sequence_id))
                })?;

                // Normalise split_time to the rate 30 for all math (MVP)
                let split_ticks = split_time.value; // at rate 30

                // Search all tracks for the clip
                let mut found_in_video: Option<usize> = None; // track index
                let mut found_in_audio: Option<usize> = None;
                let mut clip_idx_in_track: usize = 0;

                'outer_v: for (ti, track) in seq.video_tracks.iter().enumerate() {
                    for (ci, c) in track.clips.iter().enumerate() {
                        if c.id == clip_id {
                            found_in_video = Some(ti);
                            clip_idx_in_track = ci;
                            break 'outer_v;
                        }
                    }
                }
                if found_in_video.is_none() {
                    'outer_a: for (ti, track) in seq.audio_tracks.iter().enumerate() {
                        for (ci, c) in track.clips.iter().enumerate() {
                            if c.id == clip_id {
                                found_in_audio = Some(ti);
                                clip_idx_in_track = ci;
                                break 'outer_a;
                            }
                        }
                    }
                }

                if found_in_video.is_none() && found_in_audio.is_none() {
                    return Err(EngineError::new(
                        EngineErrorCode::InternalError,
                        format!("Clip {} not found in Sequence {}", clip_id, sequence_id),
                    ));
                }

                let do_split = |clips: &mut Vec<project_schema::Clip>| -> Result<(), EngineError> {
                    let clip = &clips[clip_idx_in_track];
                    let clip_start = clip.start_time.value; // ticks at rate 30
                    let clip_dur   = clip.duration.value;

                    if split_ticks <= clip_start || split_ticks >= clip_start + clip_dur {
                        return Err(EngineError::new(
                            EngineErrorCode::InternalError,
                            "split_time is outside the clip bounds",
                        ));
                    }

                    let left_dur  = split_ticks - clip_start;
                    let right_dur = clip_dur - left_dur;

                    // Build right clip first (borrows clip immutably)
                    let right_source_in_ticks = clip.source_in.value + left_dur;
                    let mut right_clip = clip.clone();
                    right_clip.id          = uuid::Uuid::new_v4();
                    right_clip.start_time  = engine_api::types::RationalTime::new(split_ticks, 30);
                    right_clip.source_in   = engine_api::types::RationalTime::new(right_source_in_ticks, 30);
                    right_clip.duration    = engine_api::types::RationalTime::new(right_dur, 30);

                    // Trim left clip
                    clips[clip_idx_in_track].duration = engine_api::types::RationalTime::new(left_dur, 30);

                    // Insert right clip after left
                    clips.insert(clip_idx_in_track + 1, right_clip);
                    Ok(())
                };

                if let Some(ti) = found_in_video {
                    do_split(&mut seq.video_tracks[ti].clips)?;
                } else if let Some(ti) = found_in_audio {
                    do_split(&mut seq.audio_tracks[ti].clips)?;
                }

                let project_id = project.project_id;
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::ImportAsset { path, add_to_composition: _ } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                use project_schema::{AssetRef, AssetKind};
                use uuid::Uuid;
                use std::path::Path;

                let p = Path::new(&path);
                let name = p.file_name()
                    .map(|n| n.to_string_lossy().to_string())
                    .unwrap_or_else(|| path.clone());
                let ext = p.extension()
                    .map(|e| e.to_string_lossy().to_string())
                    .unwrap_or_default();
                let kind = AssetKind::from_extension(&ext);
                let asset_id = Uuid::new_v4();
                let asset = AssetRef::new(asset_id, &name, &path, kind);
                let kind_copy = asset.kind;

                // Verify format using media_image if it's an image
                if kind == AssetKind::Image {
                    match media_image::probe_image(p) {
                        Ok(info) => {
                            tracing::info!("Imported Image: {}x{} (alpha: {})", info.width, info.height, info.has_alpha);
                        }
                        Err(e) => {
                            tracing::warn!("Failed to probe image asset '{}': {}", path, e);
                            return Err(EngineError::new(EngineErrorCode::AssetLoadFailed, e.to_string()));
                        }
                    }
                }
                
                // TODO(ffmpeg feature): populate fingerprint using media_ffmpeg::probe for videos
                project.assets.push(asset);
                project.touch();
                let project_id = project.project_id;

                let _ = self.event_tx.send(EngineEvent::AssetImported {
                    asset_id,
                    name,
                    kind: match kind_copy {
                        AssetKind::Video => engine_api::query::AssetKind::Video,
                        AssetKind::Audio => engine_api::query::AssetKind::Audio,
                        AssetKind::Image => engine_api::query::AssetKind::Image,
                        AssetKind::ImageSequence => engine_api::query::AssetKind::ImageSequence,
                        AssetKind::Data => engine_api::query::AssetKind::Data,
                    },
                    path,
                });
                
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::CreateCompFromAsset { asset_id } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                
                let asset = project.assets.iter().find(|a| a.id == asset_id).cloned().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::AssetLoadFailed, "Asset not found")
                })?;
                
                use engine_api::types::{Resolution, FrameRate, RationalTime};
                use project_schema::{Composition, Layer};

                let name = asset.name.clone();
                let resolution = Resolution { width: 1920, height: 1080 }; // MVP default
                let frame_rate = FrameRate { num: 30000, den: 1001 }; // MVP default
                let duration = RationalTime::new(300, 30); // 10s default
                
                let mut comp = Composition::new(&name, resolution, frame_rate, duration);
                let in_point = RationalTime::new(0, 30);
                
                let layer = Layer::new_asset(&name, asset_id, asset.kind, in_point, duration);
                comp.layers.push(layer);
                
                project.compositions.push(comp);
                project.touch();
                
                let project_id = project.project_id;
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::UpdateAssetProperties { asset_id, frame_rate } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                // Just touch for MVP to simulate property update
                project.touch();
                let project_id = project.project_id;
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::RemoveAsset { asset_id } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                project.assets.retain(|a| a.id != asset_id);
                // MVP: We don't clean up layers that use this asset yet
                project.touch();
                let project_id = project.project_id;
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id });
            }

            EngineCommand::AddLayer { composition_id, layer_type, name, index } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                let comp = project.compositions.iter_mut().find(|c| c.id == composition_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::CompositionNotFound, "Composition not found")
                })?;
                
                use project_schema::{Layer, LayerKind};
                use engine_api::types::RationalTime;
                
                let in_point = RationalTime::new(0, 30);
                let out_point = comp.duration;
                
                let layer = match layer_type {
                    engine_api::command::LayerType::Solid { color } => {
                        Layer::new_solid(name, color, in_point, out_point)
                    },
                    engine_api::command::LayerType::Asset { asset_id } => {
                        // For now we assume Video. In reality we'd look up the asset.
                        use project_schema::asset::AssetKind;
                        Layer::new_asset(name, asset_id, AssetKind::Video, in_point, out_point)
                    },
                    engine_api::command::LayerType::Null => {
                        Layer::new_null(name, in_point, out_point)
                    },
                    engine_api::command::LayerType::Text { content } => {
                        Layer::new_text(name, content, in_point, out_point)
                    },
                    _ => {
                        // Fallback for unimplemented types
                        Layer::new_null(name, in_point, out_point)
                    }
                };
                
                let layer_id = layer.id;
                
                if let Some(idx) = index {
                    let clamped = idx.min(comp.layers.len());
                    comp.layers.insert(clamped, layer);
                } else {
                    comp.layers.push(layer); // Or insert at 0 (top)
                }
                
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id: project.project_id });
            }

            EngineCommand::SetPropertyValue { composition_id, layer_id, property_path, value, time: _ } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                let comp = project.compositions.iter_mut().find(|c| c.id == composition_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::CompositionNotFound, "Composition not found")
                })?;
                let layer = comp.layer_mut(layer_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::LayerNotFound, "Layer not found")
                })?;
                
                // For MVP: only handle simple properties like "transform.position"
                match property_path.as_str() {
                    "transform.position" => layer.transform.position.static_value = Some(value),
                    "transform.opacity" => layer.transform.opacity.static_value = Some(value),
                    "transform.scale" => layer.transform.scale.static_value = Some(value),
                    "transform.rotation" => layer.transform.rotation.static_value = Some(value),
                    _ => {
                        tracing::warn!("Property path not yet implemented: {}", property_path);
                    }
                }
                
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id: project.project_id });
            }

            EngineCommand::SetLayerParent { composition_id, layer_id, parent_id } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                let comp = project.compositions.iter_mut().find(|c| c.id == composition_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::CompositionNotFound, "Composition not found")
                })?;
                
                // Ensure parent exists and no cycles (MVP: skip cycle check for now)
                if let Some(pid) = parent_id {
                    if comp.layer(pid).is_none() {
                        return Err(EngineError::new(EngineErrorCode::LayerNotFound, "Parent layer not found"));
                    }
                }

                let layer = comp.layer_mut(layer_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::LayerNotFound, "Layer not found")
                })?;

                layer.parent_id = parent_id;
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id: project.project_id });
            }

            EngineCommand::AddKeyframe { composition_id, layer_id, property_path, time, value, interpolation } => {
                let project = state.project.as_mut().ok_or_else(|| {
                    EngineError::new(EngineErrorCode::ProjectNotFound, "No project open")
                })?;
                let comp = project.compositions.iter_mut().find(|c| c.id == composition_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::CompositionNotFound, "Composition not found")
                })?;
                let layer = comp.layer_mut(layer_id).ok_or_else(|| {
                    EngineError::new(EngineErrorCode::LayerNotFound, "Layer not found")
                })?;
                
                let mut kf = project_schema::composition::Keyframe::linear(time, value);
                kf.interpolation = interpolation;

                match property_path.as_str() {
                    "transform.position" => layer.transform.position.insert_keyframe(kf),
                    "transform.opacity" => layer.transform.opacity.insert_keyframe(kf),
                    "transform.scale" => layer.transform.scale.insert_keyframe(kf),
                    "transform.rotation" => layer.transform.rotation.insert_keyframe(kf),
                    "transform.anchor_point" => layer.transform.anchor_point.insert_keyframe(kf),
                    _ => {
                        tracing::warn!("Property path not yet implemented for keyframes: {}", property_path);
                    }
                }
                
                project.touch();
                let _ = self.event_tx.send(EngineEvent::ProjectChanged { project_id: project.project_id });
            }

            EngineCommand::Undo => {
                tracing::warn!("Undo: not yet implemented in Phase 1 Q1");
            }

            EngineCommand::Redo => {
                tracing::warn!("Redo: not yet implemented in Phase 1 Q1");
            }

            other => {
                tracing::warn!("Command not yet implemented: {:?}", std::mem::discriminant(&other));
            }
        }

        Ok(())
    }

    pub fn state(&self) -> Arc<Mutex<EngineState>> {
        self.state.clone()
    }
}
