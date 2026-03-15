//! engine — Orchestration layer connecting all engine crates.
//! This is the single entry point called from `app_bridge`.

pub mod dispatcher;
pub mod state;

pub use dispatcher::EngineDispatcher;
pub use state::EngineState;
