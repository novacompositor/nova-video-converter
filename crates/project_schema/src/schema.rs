use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

use crate::settings::ProjectSettings;
use crate::asset::AssetRef;
use crate::composition::Composition;
use crate::sequence::Sequence;

/// Current schema version. Increment on breaking changes.
pub const PROJECT_SCHEMA_VERSION: u32 = 1;

/// The root struct of a `.nova` project file.
///
/// Serialized as canonical JSON on disk.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NovaProject {
    /// Immutable unique project identifier.
    pub project_id: Uuid,

    /// Schema version for migration handling.
    pub project_schema_version: u32,

    /// Engine API version that created/last modified this project.
    pub engine_api_version: String,

    /// Project display name.
    pub name: String,

    /// ISO 8601 creation timestamp.
    pub created_at: DateTime<Utc>,

    /// ISO 8601 last saved timestamp.
    pub updated_at: DateTime<Utc>,

    /// Global project settings (fps, resolution, color, audio).
    pub settings: ProjectSettings,

    /// Imported asset pool.
    pub assets: Vec<AssetRef>,

    /// All compositions in this project.
    pub compositions: Vec<Composition>,

    /// All NLE sequences in this project.
    #[serde(default)]
    pub sequences: Vec<Sequence>,

    /// Currently active composition ID (for UI state restoration).
    pub active_composition_id: Option<Uuid>,

    /// Render queue presets stored with the project.
    pub render_queue_presets: Vec<RenderQueuePreset>,

    /// UI state snapshot (workspace layout, hotkey profile, etc.).
    pub ui_state: UiState,

    /// Extension namespace for forward-compatibility.
    #[serde(default, skip_serializing_if = "serde_json::Map::is_empty")]
    pub extensions: serde_json::Map<String, serde_json::Value>,
}

impl NovaProject {
    /// Create a new empty project with sensible defaults.
    pub fn new(name: impl Into<String>, settings: ProjectSettings) -> Self {
        let now = Utc::now();
        Self {
            project_id: Uuid::new_v4(),
            project_schema_version: PROJECT_SCHEMA_VERSION,
            engine_api_version: engine_api::ENGINE_API_VERSION.to_string(),
            name: name.into(),
            created_at: now,
            updated_at: now,
            settings,
            assets: Vec::new(),
            compositions: Vec::new(),
            sequences: Vec::new(),
            active_composition_id: None,
            render_queue_presets: default_render_presets(),
            ui_state: UiState::default(),
            extensions: serde_json::Map::new(),
        }
    }

    /// Touch the `updated_at` timestamp to now.
    pub fn touch(&mut self) {
        self.updated_at = Utc::now();
    }

    /// Find a composition by ID.
    pub fn composition(&self, id: uuid::Uuid) -> Option<&Composition> {
        self.compositions.iter().find(|c| c.id == id)
    }

    /// Find a composition by ID (mutable).
    pub fn composition_mut(&mut self, id: uuid::Uuid) -> Option<&mut Composition> {
        self.compositions.iter_mut().find(|c| c.id == id)
    }

    /// Find an asset by ID.
    pub fn asset(&self, id: uuid::Uuid) -> Option<&AssetRef> {
        self.assets.iter().find(|a| a.id == id)
    }
}

/// A saved render queue preset.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RenderQueuePreset {
    pub id: Uuid,
    pub name: String,
    pub format: String,
    pub video_codec: Option<String>,
    pub audio_codec: Option<String>,
    pub extra_ffmpeg_args: Vec<String>,
}

/// Snapshot of UI state (workspace layout, hotkey profile, etc.).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct UiState {
    /// Last active workspace preset name.
    pub workspace_preset: String,
    /// Hotkey profile name.
    pub hotkey_profile: String,
    /// Per-panel layout state (serialized as opaque JSON for extensibility).
    #[serde(default)]
    pub panel_layouts: serde_json::Map<String, serde_json::Value>,
}

fn default_render_presets() -> Vec<RenderQueuePreset> {
    vec![
        RenderQueuePreset {
            id: Uuid::new_v4(),
            name: "Web H.264".into(),
            format: "mp4".into(),
            video_codec: Some("libx264".into()),
            audio_codec: Some("aac".into()),
            extra_ffmpeg_args: vec!["-crf".into(), "18".into(), "-preset".into(), "slow".into()],
        },
        RenderQueuePreset {
            id: Uuid::new_v4(),
            name: "Editing ProRes".into(),
            format: "mov".into(),
            video_codec: Some("prores_ks".into()),
            audio_codec: Some("pcm_s24le".into()),
            extra_ffmpeg_args: vec!["-profile:v".into(), "3".into()],
        },
        RenderQueuePreset {
            id: Uuid::new_v4(),
            name: "Image Sequence PNG".into(),
            format: "png".into(),
            video_codec: None,
            audio_codec: None,
            extra_ffmpeg_args: vec![],
        },
    ]
}
