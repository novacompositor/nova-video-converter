use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::types::*;

/// All commands that mutate engine state.
/// The UI dispatches commands; the engine processes them and emits Events.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum EngineCommand {
    // ---- Project lifecycle ----

    /// Create a new empty project with the given settings.
    CreateProject {
        name: String,
        resolution: Resolution,
        frame_rate: FrameRate,
        color_profile: ColorProfile,
        audio: AudioConfig,
    },

    /// Open an existing project from a file path.
    OpenProject {
        path: String,
    },

    /// Save the current project to its current path.
    SaveProject,

    /// Save the current project to a new path.
    SaveProjectAs {
        path: String,
    },

    /// Close the current project (triggers unsaved-changes check).
    CloseProject,

    // ---- Composition management ----

    /// Add a new composition to the project.
    AddComposition {
        name: String,
        resolution: Resolution,
        frame_rate: FrameRate,
        duration: RationalTime,
        color_profile: ColorProfile,
    },

    /// Create a new sequence (timeline) for video editing.
    CreateSequence {
        name: String,
        resolution: Resolution,
        frame_rate: FrameRate,
    },

    /// Add a clip to a specific track in a sequence.
    AddClipToSequence {
        sequence_id: Uuid,
        track_index: usize,
        asset_id: AssetId,
        start_time: RationalTime,
    },

    /// Move a clip to a new start time or track within a sequence.
    MoveClipInSequence {
        sequence_id: Uuid,
        clip_id: Uuid,
        new_track_index: usize,
        new_start_time: RationalTime,
    },

    /// Remove a clip from a sequence track by clip_id.
    RemoveClipFromSequence {
        sequence_id: Uuid,
        clip_id: Uuid,
    },

    /// Split a clip at an absolute timeline time, creating two clips.
    /// The original clip's duration is trimmed to the split point;
    /// a new clip is inserted immediately after it.
    SplitClipInSequence {
        sequence_id: Uuid,
        clip_id: Uuid,
        /// Absolute timeline time (in the same rate as the clip's start_time) at which to cut.
        split_time: RationalTime,
    },

    /// Remove a composition by ID.
    RemoveComposition {
        composition_id: CompositionId,
    },

    /// Set the active composition displayed in the Viewer.
    SetActiveComposition {
        composition_id: CompositionId,
    },

    // ---- Layer management ----

    /// Add a layer to a composition.
    AddLayer {
        composition_id: CompositionId,
        layer_type: LayerType,
        name: String,
        /// Insertion index (0 = top). None = append at top.
        index: Option<usize>,
    },

    /// Remove a layer from a composition.
    RemoveLayer {
        composition_id: CompositionId,
        layer_id: LayerId,
    },

    /// Reorder layer within composition.
    ReorderLayer {
        composition_id: CompositionId,
        layer_id: LayerId,
        new_index: usize,
    },

    /// Set a layer's in/out/duration.
    SetLayerTiming {
        composition_id: CompositionId,
        layer_id: LayerId,
        in_point: RationalTime,
        out_point: RationalTime,
    },

    /// Set a layer's parent (for transform inheritance).
    SetLayerParent {
        composition_id: CompositionId,
        layer_id: LayerId,
        parent_id: Option<LayerId>,
    },

    // ---- Property / Keyframe ----

    /// Set a property value at the given time (creates keyframe if property is animated).
    SetPropertyValue {
        composition_id: CompositionId,
        layer_id: LayerId,
        property_path: String, // e.g. "transform.position", "effects[0].blur_radius"
        value: PropertyValue,
        time: RationalTime,
    },

    /// Add an explicit keyframe.
    AddKeyframe {
        composition_id: CompositionId,
        layer_id: LayerId,
        property_path: String,
        time: RationalTime,
        value: PropertyValue,
        interpolation: Interpolation,
    },

    /// Remove a keyframe by ID.
    RemoveKeyframe {
        composition_id: CompositionId,
        layer_id: LayerId,
        property_path: String,
        keyframe_id: KeyframeId,
    },

    /// Enable/disable keyframing (hold/animate toggle) for a property.
    SetPropertyAnimated {
        composition_id: CompositionId,
        layer_id: LayerId,
        property_path: String,
        animated: bool,
    },

    // ---- Media / Assets ----

    /// Import a media file into the project's asset pool.
    ImportAsset {
        path: String,
        /// Optional composition to add as layer after import.
        add_to_composition: Option<CompositionId>,
    },

    /// Create a new composition matching an asset's properties.
    CreateCompFromAsset {
        asset_id: AssetId,
    },

    /// Update asset interpretation properties.
    UpdateAssetProperties {
        asset_id: AssetId,
        frame_rate: Option<FrameRate>,
    },

    /// Relink an offline asset to a new path.
    RelinkAsset {
        asset_id: AssetId,
        new_path: String,
    },

    /// Remove an asset from the project (and orphan any layers using it).
    RemoveAsset {
        asset_id: AssetId,
    },

    // ---- Playback ----

    /// Start playback from the current playhead position.
    StartPlayback {
        composition_id: CompositionId,
    },

    /// Stop/pause playback.
    StopPlayback,

    /// Seek playhead to a specific time.
    SeekTo {
        composition_id: CompositionId,
        time: RationalTime,
    },

    // ---- Render queue ----

    /// Add a render job to the queue.
    QueueRenderJob {
        composition_id: CompositionId,
        output_path: String,
        preset: RenderPreset,
        options: Option<ConvertOptions>,
    },

    /// Start processing the render queue.
    StartRenderQueue,

    /// Cancel a specific render job.
    CancelRenderJob {
        job_id: uuid::Uuid,
    },

    // ---- Effects ----

    /// Add an effect to a layer.
    AddEffect {
        composition_id: CompositionId,
        layer_id: LayerId,
        effect_type: String,
    },

    /// Remove an effect from a layer.
    RemoveEffect {
        composition_id: CompositionId,
        layer_id: LayerId,
        effect_index: usize,
    },

    // ---- Undo/Redo ----
    Undo,
    Redo,
}

/// Layer type variants.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum LayerType {
    /// A media asset layer (video/image/audio).
    Asset { asset_id: AssetId },
    /// A solid color layer.
    Solid { color: [f64; 4] },
    /// A text layer.
    Text { content: String },
    /// An adjustment layer (applies effects to layers below).
    Adjustment,
    /// A null layer (for parenting/expressions).
    Null,
    /// A shape layer.
    Shape,
    /// A camera layer (3D).
    Camera,
    /// A light layer (3D).
    Light,
}

/// Render output preset.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RenderPreset {
    pub name: String,
    pub format: RenderFormat,
    pub video_codec: Option<String>,
    pub audio_codec: Option<String>,
    pub quality: RenderQuality,
}

impl RenderPreset {
    pub fn h264_web() -> Self {
        Self {
            name: "Web H.264".into(),
            format: RenderFormat::Mp4,
            video_codec: Some("libx264".into()),
            audio_codec: Some("aac".into()),
            quality: RenderQuality::High,
        }
    }

    pub fn prores_editing() -> Self {
        Self {
            name: "Editing ProRes".into(),
            format: RenderFormat::Mov,
            video_codec: Some("prores_ks".into()),
            audio_codec: Some("pcm_s24le".into()),
            quality: RenderQuality::Lossless,
        }
    }

    pub fn image_sequence_png() -> Self {
        Self {
            name: "Image Sequence PNG".into(),
            format: RenderFormat::ImageSequence { ext: "png".into() },
            video_codec: None,
            audio_codec: None,
            quality: RenderQuality::Lossless,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum RenderFormat {
    Mp4,
    Mov,
    Mkv,
    Gif,
    ImageSequence { ext: String },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum RenderQuality {
    #[default]
    High,
    Medium,
    Low,
    Lossless,
}

/// Advanced options for conversion and export.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct ConvertOptions {
    pub split_scenes: bool,
    pub scene_threshold: f32, // 0.1 - 0.9
    pub gif_fps: u32,
    pub gif_width: u32,
    pub gif_colors: u32,
}

impl RenderPreset {
    pub fn gif_social() -> Self {
        Self {
            name: "Social GIF".into(),
            format: RenderFormat::Gif,
            video_codec: Some("gif".into()),
            audio_codec: None,
            quality: RenderQuality::High,
        }
    }
}
