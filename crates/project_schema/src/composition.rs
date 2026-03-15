use serde::{Deserialize, Serialize};
use uuid::Uuid;
use engine_api::types::{Resolution, FrameRate, ColorProfile, RationalTime, PropertyValue, Interpolation};

use crate::asset::AssetKind;

/// A composition (equivalent to AE composition / timeline).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Composition {
    pub id: Uuid,
    pub name: String,
    pub resolution: Resolution,
    pub frame_rate: FrameRate,
    /// Total duration of this composition.
    pub duration: RationalTime,
    pub color_profile: ColorProfile,
    /// Ordered layer stack (index 0 = top/front).
    pub layers: Vec<Layer>,
    /// Composition background color (RGBA 0.0–1.0).
    #[serde(default = "default_bg_color")]
    pub background_color: [f64; 4],
}

fn default_bg_color() -> [f64; 4] { [0.0, 0.0, 0.0, 1.0] }

impl Composition {
    pub fn new(name: impl Into<String>, resolution: Resolution, frame_rate: FrameRate, duration: RationalTime) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            resolution,
            frame_rate,
            duration,
            color_profile: ColorProfile::LinearSRGB,
            layers: Vec::new(),
            background_color: [0.0, 0.0, 0.0, 1.0],
        }
    }

    pub fn layer(&self, id: Uuid) -> Option<&Layer> {
        self.layers.iter().find(|l| l.id == id)
    }

    pub fn layer_mut(&mut self, id: Uuid) -> Option<&mut Layer> {
        self.layers.iter_mut().find(|l| l.id == id)
    }
}

/// A single layer within a composition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Layer {
    pub id: Uuid,
    pub name: String,
    /// Layer type and type-specific data.
    pub kind: LayerKind,
    /// Layer in-point (start time within composition).
    pub in_point: RationalTime,
    /// Layer out-point (end time within composition).
    pub out_point: RationalTime,
    /// Whether this layer is visible in the viewer.
    #[serde(default = "default_true")]
    pub visible: bool,
    /// Solo mode (only soloed layers render).
    #[serde(default)]
    pub solo: bool,
    /// Locked (cannot be selected/modified in UI).
    #[serde(default)]
    pub locked: bool,
    /// Shy (hidden in timeline when Shy toggle is on).
    #[serde(default)]
    pub shy: bool,
    /// Parent layer ID for parenting/inheritance.
    pub parent_id: Option<Uuid>,
    /// 3D layer mode.
    #[serde(default)]
    pub is_3d: bool,
    /// Motion blur enabled.
    #[serde(default)]
    pub motion_blur: bool,
    /// Collapse transformations (for pre-comp layers).
    #[serde(default)]
    pub collapse_transform: bool,
    /// Transform properties.
    pub transform: Transform,
    /// Applied effects (in order).
    #[serde(default)]
    pub effects: Vec<Effect>,
    /// Layer blend mode.
    #[serde(default)]
    pub blend_mode: BlendMode,
    /// Track matte mode.
    #[serde(default)]
    pub track_matte: TrackMatteMode,
}

fn default_true() -> bool { true }

impl Layer {
    pub fn new_solid(name: impl Into<String>, color: [f64; 4], in_point: RationalTime, out_point: RationalTime) -> Self {
        Self::base(name, LayerKind::Solid { color }, in_point, out_point)
    }

    pub fn new_null(name: impl Into<String>, in_point: RationalTime, out_point: RationalTime) -> Self {
        Self::base(name, LayerKind::Null, in_point, out_point)
    }

    pub fn new_asset(name: impl Into<String>, asset_id: Uuid, asset_kind: AssetKind, in_point: RationalTime, out_point: RationalTime) -> Self {
        Self::base(name, LayerKind::Asset { asset_id, asset_kind }, in_point, out_point)
    }

    pub fn new_text(name: impl Into<String>, content: impl Into<String>, in_point: RationalTime, out_point: RationalTime) -> Self {
        Self::base(name, LayerKind::Text {
            content: content.into(),
            font_family: "Inter".into(),
            font_size: 48.0,
        }, in_point, out_point)
    }

    fn base(name: impl Into<String>, kind: LayerKind, in_point: RationalTime, out_point: RationalTime) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            kind,
            in_point,
            out_point,
            visible: true,
            solo: false,
            locked: false,
            shy: false,
            parent_id: None,
            is_3d: false,
            motion_blur: false,
            collapse_transform: false,
            transform: Transform::default(),
            effects: Vec::new(),
            blend_mode: BlendMode::Normal,
            track_matte: TrackMatteMode::None,
        }
    }
}

/// Layer type variants.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum LayerKind {
    Asset { asset_id: Uuid, asset_kind: AssetKind },
    Solid { color: [f64; 4] },
    Text { content: String, font_family: String, font_size: f64 },
    Adjustment,
    Null,
    Shape { shapes: Vec<serde_json::Value> }, // Detailed shape data deferred to Phase 1 Q3
    Camera { fov_degrees: f64 },
    Light { light_type: LightType, color: [f64; 3], intensity: f64 },
    PreComp { composition_id: Uuid },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum LightType { #[default] Point, Spot, Ambient, Parallel }

/// Animatable transform for a layer.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Transform {
    pub anchor_point: KeyframeChannel,
    pub position: KeyframeChannel,
    pub scale: KeyframeChannel,
    pub rotation: KeyframeChannel,
    pub opacity: KeyframeChannel,
}

impl Default for Transform {
    fn default() -> Self {
        Self {
            anchor_point: KeyframeChannel::from_value(PropertyValue::Vec2 { x: 0.0, y: 0.0 }),
            position: KeyframeChannel::from_value(PropertyValue::Vec2 { x: 960.0, y: 540.0 }),
            scale: KeyframeChannel::from_value(PropertyValue::Vec2 { x: 100.0, y: 100.0 }),
            rotation: KeyframeChannel::from_value(PropertyValue::Float(0.0)),
            opacity: KeyframeChannel::from_value(PropertyValue::Float(100.0)),
        }
    }
}

/// A single animatable property channel.
/// Either a static value OR a list of keyframes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct KeyframeChannel {
    /// Static value (used when not animated).
    pub static_value: Option<PropertyValue>,
    /// Keyframes (when animated).
    #[serde(default)]
    pub keyframes: Vec<Keyframe>,
}

impl KeyframeChannel {
    pub fn from_value(v: PropertyValue) -> Self {
        Self { static_value: Some(v), keyframes: Vec::new() }
    }

    pub fn is_animated(&self) -> bool { !self.keyframes.is_empty() }

    /// Insert or update a keyframe at the exact time. Maintains chronological sort.
    pub fn insert_keyframe(&mut self, kf: Keyframe) {
        // Find existing keyframe at exact time to overwrite
        if let Some(existing) = self.keyframes.iter_mut().find(|k| {
            // Precise temporal comparison
            k.time.value * (kf.time.rate as i64) == kf.time.value * (k.time.rate as i64)
        }) {
            existing.value = kf.value;
            existing.interpolation = kf.interpolation;
            existing.tangent_in = kf.tangent_in;
            existing.tangent_out = kf.tangent_out;
            return;
        }

        self.keyframes.push(kf);
        // Keep sorted
        self.keyframes.sort_by(|a, b| {
            let left = a.time.value * (b.time.rate as i64);
            let right = b.time.value * (a.time.rate as i64);
            left.cmp(&right)
        });
    }
}

/// A single keyframe on a channel.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Keyframe {
    pub id: Uuid,
    pub time: RationalTime,
    pub value: PropertyValue,
    pub interpolation: Interpolation,
    /// Bezier in-tangent (for bezier interpolation).
    pub tangent_in: Option<[f64; 2]>,
    /// Bezier out-tangent (for bezier interpolation).
    pub tangent_out: Option<[f64; 2]>,
}

impl Keyframe {
    pub fn linear(time: RationalTime, value: PropertyValue) -> Self {
        Self {
            id: Uuid::new_v4(),
            time,
            value,
            interpolation: Interpolation::Linear,
            tangent_in: None,
            tangent_out: None,
        }
    }
}

/// An applied effect on a layer.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Effect {
    pub id: Uuid,
    pub effect_type: String, // e.g. "nova.built_in.blur_gaussian"
    pub name: String,
    #[serde(default = "default_true")]
    pub enabled: bool,
    pub params: Vec<EffectParam>,
}

/// An effect parameter (animatable).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EffectParam {
    pub name: String,
    pub path: String,
    pub channel: KeyframeChannel,
}

/// Layer blend modes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum BlendMode {
    #[default] Normal,
    Add,
    Screen,
    Multiply,
    Overlay,
    SoftLight,
    HardLight,
    Difference,
    Exclusion,
    Hue,
    Saturation,
    Color,
    Luminosity,
    Darken,
    Lighten,
    ColorDodge,
    ColorBurn,
    LinearBurn,
    LinearLight,
    PinLight,
}

/// Track matte mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub enum TrackMatteMode {
    #[default] None,
    AlphaMatte,
    AlphaInvertedMatte,
    LumaMatte,
    LumaInvertedMatte,
}
