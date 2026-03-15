use serde::{Deserialize, Serialize};
use engine_api::types::{Resolution, FrameRate, ColorProfile, AudioConfig};

/// Global project settings shared across all compositions by default.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProjectSettings {
    /// Default output resolution.
    pub resolution: Resolution,

    /// Default frame rate (rational).
    pub frame_rate: FrameRate,

    /// Working color space.
    pub color_profile: ColorProfile,

    /// Audio settings.
    pub audio: AudioConfig,

    /// Whether to use proxy media by default for new compositions.
    pub use_proxy: bool,

    /// Autosave interval in seconds (0 = disabled).
    pub autosave_interval_secs: u32,

    /// Maximum number of autosave snapshots to retain.
    pub autosave_keep_count: u32,
}

impl Default for ProjectSettings {
    fn default() -> Self {
        Self {
            resolution: Resolution::hd(),
            frame_rate: FrameRate::fps24(),
            color_profile: ColorProfile::LinearSRGB,
            audio: AudioConfig::default(),
            use_proxy: false,
            autosave_interval_secs: 60,
            autosave_keep_count: 30,
        }
    }
}

impl ProjectSettings {
    pub fn hd24() -> Self { Self::default() }

    pub fn uhd30() -> Self {
        Self {
            resolution: Resolution::uhd(),
            frame_rate: FrameRate::fps30(),
            ..Self::default()
        }
    }
}
