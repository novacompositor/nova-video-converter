pub mod schema;
pub mod settings;
pub mod asset;
pub mod composition;
pub mod migration;
pub mod sequence;
pub mod xml_parser;
pub mod io;
pub mod validation;

pub use schema::{NovaProject, PROJECT_SCHEMA_VERSION};
pub use settings::ProjectSettings;
pub use asset::{AssetRef, AssetFingerprint, AssetKind};
pub use composition::{Composition, Layer, LayerKind, Transform, KeyframeChannel};
pub use sequence::{Sequence, Track, TrackKind, Clip, ClipItem};
pub use migration::MigrationRunner;
pub use io::{ProjectIo, AutosaveManager, RecoveryInfo};
