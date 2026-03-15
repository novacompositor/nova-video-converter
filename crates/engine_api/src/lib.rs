/// ENGINE_API_VERSION — semver string for bridge compatibility checks.
pub const ENGINE_API_VERSION: &str = "0.1.0";

pub mod command;
pub mod event;
pub mod query;
pub mod error;
pub mod types;

pub use command::EngineCommand;
pub use event::EngineEvent;
pub use query::{EngineQuery, QueryResult};
pub use error::EngineError;
pub use types::{
    AssetId, CompositionId, LayerId, ProjectId,
    RationalTime, Resolution, ColorProfile, AudioConfig,
};
