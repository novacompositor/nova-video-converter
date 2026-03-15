use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A reference to an imported media asset.
/// The project stores URI references, NOT embedded raw media.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AssetRef {
    /// Unique asset ID.
    pub id: Uuid,

    /// Display name (derived from filename by default).
    pub name: String,

    /// Absolute or relative URI to the source file.
    pub uri: String,

    /// Asset type.
    pub kind: AssetKind,

    /// Fingerprint for relink matching.
    pub fingerprint: AssetFingerprint,

    /// Whether this asset is currently online (reachable).
    #[serde(default = "default_true")]
    pub online: bool,

    /// Path to proxy media (if any). In `bundle/proxy/` subdirectory.
    pub proxy_uri: Option<String>,

    /// Whether to use proxy for this asset.
    #[serde(default)]
    pub use_proxy: bool,

    /// Optional user-set label color (hex).
    pub label_color: Option<String>,
}

fn default_true() -> bool { true }

impl AssetRef {
    pub fn new(id: Uuid, name: impl Into<String>, uri: impl Into<String>, kind: AssetKind) -> Self {
        Self {
            id,
            name: name.into(),
            uri: uri.into(),
            kind,
            fingerprint: AssetFingerprint::default(),
            online: true,
            proxy_uri: None,
            use_proxy: false,
            label_color: None,
        }
    }
}

/// Content fingerprint for relink matching.
/// Computed on import; used to find moved files.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct AssetFingerprint {
    /// File size in bytes.
    pub size_bytes: Option<u64>,
    /// Duration in milliseconds (for AV assets).
    pub duration_ms: Option<u64>,
    /// Frame count (for video/image sequence assets).
    pub frame_count: Option<u64>,
    /// Video width in pixels.
    pub width: Option<u32>,
    /// Video height in pixels.
    pub height: Option<u32>,
    /// Audio sample rate (Hz).
    pub sample_rate: Option<u32>,
    /// SHA-256 hash of the first 64 KB (partial hash for speed).
    pub partial_hash: Option<String>,
}

/// Asset kind / media type.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AssetKind {
    Video,
    Audio,
    Image,
    ImageSequence,
    Data,
}

impl AssetKind {
    pub fn from_extension(ext: &str) -> Self {
        match ext.to_lowercase().as_str() {
            "mp4" | "mov" | "mkv" | "avi" | "webm" | "mxf" | "r3d" | "braw" => AssetKind::Video,
            "mp3" | "wav" | "aif" | "aiff" | "flac" | "ogg" | "m4a" => AssetKind::Audio,
            "png" | "jpg" | "jpeg" | "tif" | "tiff" | "exr" | "dpx" | "hdr" | "psd" => AssetKind::Image,
            _ => AssetKind::Data,
        }
    }
}
