use crate::schema::{NovaProject, PROJECT_SCHEMA_VERSION};
use crate::io::IoError;

/// Migration runner: upgrades a project from its current schema version
/// to `PROJECT_SCHEMA_VERSION` by running a chain of migrators.
pub struct MigrationRunner;

impl MigrationRunner {
    /// Run all required migrations on `project`.
    /// Returns `Err` if migration chain cannot be completed.
    pub fn migrate(project: &mut NovaProject) -> Result<(), MigrationError> {
        let mut version = project.project_schema_version;

        while version < PROJECT_SCHEMA_VERSION {
            match version {
                0 => migrate_v0_to_v1(project)?,
                _ => return Err(MigrationError::NoMigratorFound { from: version }),
            }
            version += 1;
            project.project_schema_version = version;
        }

        Ok(())
    }

    /// Returns true if the project needs migration.
    pub fn needs_migration(project: &NovaProject) -> bool {
        project.project_schema_version < PROJECT_SCHEMA_VERSION
    }

    /// Returns true if the project's schema version is too new (from a future engine version).
    pub fn is_too_new(project: &NovaProject) -> bool {
        project.project_schema_version > PROJECT_SCHEMA_VERSION
    }
}

// ---- Individual migrators ----

/// Migrate schema v0 → v1.
/// v0 was the pre-release draft. v1 is the initial stable format.
/// This is mostly a no-op for new projects but ensures the schema_version field is set.
fn migrate_v0_to_v1(project: &mut NovaProject) -> Result<(), MigrationError> {
    // In v0→v1: ensure all compositions have a non-zero background_color set.
    for comp in &mut project.compositions {
        // background_color defaults to black; nothing to migrate for v0.
        let _ = comp; // explicit no-op
    }
    Ok(())
}

// ---- Error ----

#[derive(Debug, thiserror::Error)]
pub enum MigrationError {
    #[error("No migrator found for schema version {from}")]
    NoMigratorFound { from: u32 },
    #[error("Schema version {version} is newer than engine supports ({max})")]
    TooNew { version: u32, max: u32 },
    #[error("Migration I/O error: {0}")]
    Io(#[from] IoError),
}
