use project_schema::NovaProject;

/// In-memory engine state. Single source of truth for project data.
#[derive(Debug, Default)]
pub struct EngineState {
    /// Currently open project, if any.
    pub project: Option<NovaProject>,
    /// File path of the currently open project.
    pub project_path: Option<String>,
    /// Whether playback is active.
    pub is_playing: bool,
}
