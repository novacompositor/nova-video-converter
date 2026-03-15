use serde::{Deserialize, Serialize};
use crate::types::*;
use crate::query::AssetKind;

/// Events emitted asynchronously by the engine to notify the UI of state changes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum EngineEvent {
    // ---- Project ----

    /// Project state has changed (reload project tree).
    ProjectChanged {
        project_id: ProjectId,
    },

    /// A project was successfully opened.
    ProjectOpened {
        project_id: ProjectId,
        name: String,
        path: String,
    },

    /// Project was saved.
    ProjectSaved {
        path: String,
    },

    /// Project was closed.
    ProjectClosed,

    // ---- Timeline / Composition ----

    /// Timeline/composition state has been invalidated (re-query).
    TimelineInvalidated {
        composition_id: CompositionId,
        /// Which layers are affected (None = all).
        affected_layers: Option<Vec<LayerId>>,
    },

    // ---- Rendering / Playback ----

    /// A rendered frame is ready for display in the Viewer.
    FrameReady {
        composition_id: CompositionId,
        time: RationalTime,
        /// Raw RGBA pixel data (width × height × 4 bytes).
        /// On the bridge, this will be transferred via shared memory / texture handle.
        width: u32,
        height: u32,
        /// Unique frame token — UI can use to request pixel data via bridge.
        frame_token: u64,
    },

    /// Playback state changed (playing/stopped/seeking).
    PlaybackStateChanged {
        is_playing: bool,
        current_time: RationalTime,
        actual_fps: f64,
    },

    /// Render job progress update.
    RenderProgress {
        job_id: uuid::Uuid,
        progress: f32, // 0.0..1.0
        current_frame: u64,
        total_frames: u64,
        elapsed_seconds: f64,
        eta_seconds: Option<f64>,
    },

    /// Render job completed successfully.
    RenderCompleted {
        job_id: uuid::Uuid,
        output_path: String,
        elapsed_seconds: f64,
    },

    /// Render job failed.
    RenderFailed {
        job_id: uuid::Uuid,
        error: String,
    },

    // ---- Media / Assets ----

    /// Asset has become offline (file moved/deleted).
    MediaOfflineDetected {
        asset_id: AssetId,
        last_known_path: String,
    },

    /// Asset was re-linked and is online again.
    MediaRelinked {
        asset_id: AssetId,
        new_path: String,
    },

    /// Asset import completed.
    AssetImported {
        asset_id: AssetId,
        name: String,
        kind: AssetKind,
        path: String,
    },

    /// Asset import failed.
    AssetImportFailed {
        path: String,
        error: String,
    },

    // ---- GPU / System ----

    /// GPU backend has fallen back to CPU due to an error/unavailability.
    GpuFallbackActivated {
        reason: String,
        backend_now: String,
    },

    /// A recoverable engine warning (show in status bar, not a dialog).
    Warning {
        code: String,
        message: String,
    },

    /// Autosave snapshot was written.
    AutosaveWritten {
        snapshot_path: String,
        timestamp: String,
    },

    /// Recovery wizard should be shown (crash snapshots found).
    RecoveryAvailable {
        snapshot_count: usize,
        latest_snapshot: String,
    },
}
