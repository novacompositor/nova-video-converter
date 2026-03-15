use serde::{Deserialize, Serialize};
use crate::types::*;

/// Queries are read-only snapshot requests from the UI to the engine.
/// They never mutate state.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum EngineQuery {
    /// Get the project tree (compositions, assets, metadata).
    GetProjectTree,

    /// Get the full timeline view for a composition.
    GetTimelineView {
        composition_id: CompositionId,
    },

    /// Get all properties and their current values for a layer at a given time.
    GetLayerProperties {
        composition_id: CompositionId,
        layer_id: LayerId,
        time: RationalTime,
    },

    /// Get keyframe data for the graph editor.
    GetGraphEditorData {
        composition_id: CompositionId,
        layer_ids: Vec<LayerId>,
        property_paths: Vec<String>,
    },

    /// Get current playback status.
    GetPlaybackStatus,

    /// Get the render queue state.
    GetRenderQueue,

    /// Get info about a specific asset.
    GetAssetInfo {
        asset_id: AssetId,
    },

    /// Get engine diagnostics (GPU info, backend, perf counters).
    GetDiagnostics,
}

/// Unified result type returned by the engine for queries.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "data")]
pub enum QueryResult {
    ProjectTree(ProjectTreeView),
    TimelineView(TimelineView),
    LayerProperties(LayerPropertiesView),
    GraphEditorData(GraphEditorView),
    PlaybackStatus(PlaybackStatusView),
    RenderQueue(RenderQueueView),
    AssetInfo(AssetInfoView),
    Diagnostics(DiagnosticsView),
}

// ---- View model structs ----

/// Lightweight project tree for the Project Panel.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProjectTreeView {
    pub project_id: ProjectId,
    pub name: String,
    pub compositions: Vec<CompositionSummary>,
    pub assets: Vec<AssetSummary>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CompositionSummary {
    pub id: CompositionId,
    pub name: String,
    pub duration: RationalTime,
    pub frame_rate: FrameRate,
    pub resolution: Resolution,
    pub layer_count: usize,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AssetSummary {
    pub id: AssetId,
    pub name: String,
    pub path: String,
    pub kind: AssetKind,
    pub online: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AssetKind {
    Video,
    Audio,
    Image,
    ImageSequence,
    Data,
}

/// Timeline view model for Timeline Panel.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TimelineView {
    pub composition_id: CompositionId,
    pub duration: RationalTime,
    pub frame_rate: FrameRate,
    pub layers: Vec<LayerView>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LayerView {
    pub id: LayerId,
    pub name: String,
    pub index: usize,
    pub in_point: RationalTime,
    pub out_point: RationalTime,
    pub visible: bool,
    pub solo: bool,
    pub locked: bool,
    pub shy: bool,
    pub has_effects: bool,
    pub is_3d: bool,
    pub parent_id: Option<LayerId>,
}

/// Layer properties view model for Effect Controls Panel.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LayerPropertiesView {
    pub layer_id: LayerId,
    pub time: RationalTime,
    pub transform: TransformValues,
    pub effects: Vec<EffectView>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TransformValues {
    pub anchor_point: [f64; 2],
    pub position: [f64; 2],
    pub scale: [f64; 2],
    pub rotation: f64,
    pub opacity: f64,
}

impl Default for TransformValues {
    fn default() -> Self {
        Self {
            anchor_point: [0.0, 0.0],
            position: [0.0, 0.0],
            scale: [100.0, 100.0],
            rotation: 0.0,
            opacity: 100.0,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EffectView {
    pub index: usize,
    pub effect_type: String,
    pub name: String,
    pub enabled: bool,
    pub params: Vec<EffectParam>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EffectParam {
    pub name: String,
    pub path: String,
    pub value: crate::types::PropertyValue,
    pub animated: bool,
}

/// Graph editor data.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GraphEditorView {
    pub curves: Vec<AnimationCurve>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AnimationCurve {
    pub layer_id: LayerId,
    pub property_path: String,
    pub keyframes: Vec<KeyframeView>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct KeyframeView {
    pub id: uuid::Uuid,
    pub time: RationalTime,
    pub value: crate::types::PropertyValue,
    pub interpolation: crate::types::Interpolation,
}

/// Playback status.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PlaybackStatusView {
    pub is_playing: bool,
    pub current_time: RationalTime,
    pub loop_enabled: bool,
    pub actual_fps: f64,
}

/// Render queue view model.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RenderQueueView {
    pub jobs: Vec<RenderJobView>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RenderJobView {
    pub job_id: uuid::Uuid,
    pub composition_id: CompositionId,
    pub output_path: String,
    pub status: RenderJobStatus,
    pub progress: f32, // 0.0..1.0
    pub error: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RenderJobStatus {
    Queued,
    Rendering,
    Completed,
    Failed,
    Cancelled,
}

/// Asset info.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AssetInfoView {
    pub id: AssetId,
    pub path: String,
    pub name: String,
    pub kind: AssetKind,
    pub online: bool,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub duration: Option<RationalTime>,
    pub frame_rate: Option<FrameRate>,
    pub audio_channels: Option<u8>,
    pub sample_rate: Option<u32>,
}

/// Engine diagnostics.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DiagnosticsView {
    pub engine_api_version: String,
    pub gpu_backend: String,
    pub gpu_name: String,
    pub gpu_fallback_active: bool,
    pub cpu_cores: usize,
    pub memory_mb: u64,
}
