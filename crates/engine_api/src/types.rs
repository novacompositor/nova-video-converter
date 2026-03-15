use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Unique identifier for a Project.
pub type ProjectId = Uuid;

/// Unique identifier for a Composition.
pub type CompositionId = Uuid;

/// Unique identifier for a Layer.
pub type LayerId = Uuid;

/// Unique identifier for an imported Asset.
pub type AssetId = Uuid;

/// Unique identifier for a Keyframe.
pub type KeyframeId = Uuid;

/// Rational time representation: numerator / denominator ticks.
/// Used everywhere instead of floating-point seconds to avoid precision drift.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct RationalTime {
    /// Numerator (frame count or sub-frame ticks).
    pub value: i64,
    /// Denominator (timebase, e.g. 24, 30, 48000 for audio).
    pub rate: u32,
}

impl RationalTime {
    pub fn new(value: i64, rate: u32) -> Self {
        Self { value, rate }
    }

    pub fn zero(rate: u32) -> Self {
        Self { value: 0, rate }
    }

    /// Convert to seconds as f64 (for display / audio sync only).
    pub fn as_seconds_f64(&self) -> f64 {
        self.value as f64 / self.rate as f64
    }

    /// Convert to frame index at given FPS.
    pub fn to_frame(&self, fps_num: u32, fps_den: u32) -> i64 {
        // value/rate * fps_num/fps_den
        self.value * fps_num as i64 / (self.rate as i64 * fps_den as i64)
    }
}

/// Output resolution.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Resolution {
    pub width: u32,
    pub height: u32,
}

impl Resolution {
    pub fn new(width: u32, height: u32) -> Self {
        Self { width, height }
    }

    pub fn hd() -> Self {
        Self::new(1920, 1080)
    }
    pub fn uhd() -> Self {
        Self::new(3840, 2160)
    }
}

/// Color profile / working color space.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum ColorProfile {
    #[default]
    LinearSRGB,
    SRGB,
    Rec709,
    Rec2020,
    ACES,
    Custom(String),
}

/// Audio configuration for a composition.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AudioConfig {
    pub sample_rate: u32,
    pub channels: u8,
    pub bit_depth: u8,
}

impl Default for AudioConfig {
    fn default() -> Self {
        Self {
            sample_rate: 48000,
            channels: 2,
            bit_depth: 24,
        }
    }
}

/// FPS representation as rational (numerator, denominator).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct FrameRate {
    pub num: u32,
    pub den: u32,
}

impl FrameRate {
    pub fn new(num: u32, den: u32) -> Self {
        Self { num, den }
    }
    pub fn fps24() -> Self {
        Self::new(24, 1)
    }
    pub fn fps25() -> Self {
        Self::new(25, 1)
    }
    pub fn fps30() -> Self {
        Self::new(30, 1)
    }
    pub fn fps60() -> Self {
        Self::new(60, 1)
    }
    pub fn fps_ntsc() -> Self {
        Self::new(30000, 1001)
    }

    pub fn as_f64(&self) -> f64 {
        self.num as f64 / self.den as f64
    }
}

/// Property value type — covers all animatable value kinds.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum PropertyValue {
    Float(f64),
    Vec2 { x: f64, y: f64 },
    Vec3 { x: f64, y: f64, z: f64 },
    Color { r: f64, g: f64, b: f64, a: f64 },
    Bool(bool),
    Int(i64),
    Text(String),
}

/// Interpolation method for keyframes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum Interpolation {
    #[default]
    Linear,
    Hold,
    BezierIn,
    BezierOut,
    BezierInOut,
    EaseIn,
    EaseOut,
    EaseInOut,
}
