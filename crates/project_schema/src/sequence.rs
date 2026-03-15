use serde::{Deserialize, Serialize};
use uuid::Uuid;
use engine_api::types::{Resolution, FrameRate, ColorProfile, RationalTime};

use crate::asset::AssetKind;
use crate::composition::Transform;

/// A sequence (equivalent to an NLE timeline, like Premiere/FCP).
/// Optimized for linear editing, cutting, and simple track stacking.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Sequence {
    pub id: Uuid,
    pub name: String,
    pub resolution: Resolution,
    pub frame_rate: FrameRate,
    pub color_profile: ColorProfile,
    /// Video tracks (index 0 = top track, e.g., V3, V2, V1).
    pub video_tracks: Vec<Track>,
    /// Audio tracks (index 0 = A1, index 1 = A2, etc.).
    pub audio_tracks: Vec<Track>,
}

impl Sequence {
    pub fn new(name: impl Into<String>, resolution: Resolution, frame_rate: FrameRate) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            resolution,
            frame_rate,
            color_profile: ColorProfile::LinearSRGB,
            video_tracks: Vec::new(),
            audio_tracks: Vec::new(),
        }
    }
}

/// A track containing multiple clips placed serially.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Track {
    pub id: Uuid,
    pub name: String,
    pub kind: TrackKind,
    pub visible: bool,
    pub locked: bool,
    pub solo: bool,
    pub mute: bool,
    /// Clips placed on this track. Must not overlap in time.
    pub clips: Vec<Clip>,
}

impl Track {
    pub fn new(name: impl Into<String>, kind: TrackKind) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            kind,
            visible: true,
            locked: false,
            solo: false,
            mute: false,
            clips: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TrackKind {
    Video,
    Audio,
}

/// A single clip (media chunk) placed on a timeline track.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Clip {
    pub id: Uuid,
    pub name: String,
    pub item: ClipItem,
    
    /// Global start time where this clip begins on the timeline track.
    pub start_time: RationalTime,
    
    /// The start time within the source media (i.e., trim in-point).
    /// If the media is 10s long, and `source_in` is 2s, we ignore the first 2s.
    pub source_in: RationalTime,
    
    /// The duration of the clip *on the timeline*.
    /// E.g., if duration is 5s, it plays from `source_in` to `source_in + 5s`.
    pub duration: RationalTime,
    
    /// Playback speed multiplier (1.0 = normal, -1.0 = reverse, 2.0 = 2x speed).
    pub speed: f64,

    /// Enabled state for whether the clip is active during playback/render.
    #[serde(default = "default_true")]
    pub enabled: bool,
    
    /// Transform properties on the track timeline (Scale/Position/Rotation).
    pub transform: Transform,
}

fn default_true() -> bool { true }

impl Clip {
    pub fn new_asset(
        name: impl Into<String>,
        asset_id: Uuid,
        asset_kind: AssetKind,
        start_time: RationalTime,
        source_in: RationalTime,
        duration: RationalTime,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            item: ClipItem::Asset { asset_id, asset_kind },
            start_time,
            source_in,
            duration,
            speed: 1.0,
            enabled: true,
            transform: Transform::default(),
        }
    }
}

/// The media content inside a clip.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum ClipItem {
    /// A reference to an imported project asset (Video, Audio, Image).
    Asset { asset_id: Uuid, asset_kind: AssetKind },
    /// A nested composition serving as a clip.
    Composition { composition_id: Uuid },
    /// A nested sequence serving as a clip.
    Sequence { sequence_id: Uuid },
    /// A solid color generator.
    Solid { color: [f64; 4] },
    /// Plain text generator.
    Title { content: String },
}
