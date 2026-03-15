use std::fs;
use std::path::{Path, PathBuf};
use std::io::Write;
use serde::{Deserialize, Serialize};
use chrono::Utc;

use crate::schema::NovaProject;

// ---- Atomic I/O ----

/// Project file I/O: atomic save, load, validation.
pub struct ProjectIo;

impl ProjectIo {
    /// Atomically serialize and write a project to `path`.
    /// Strategy: write to `<path>.tmp` → fsync → rename.
    pub fn save(project: &NovaProject, path: &Path) -> Result<(), IoError> {
        let json = serde_json::to_string_pretty(project)
            .map_err(|e| IoError::Serialize(e.to_string()))?;

        let tmp_path = path.with_extension("nova.tmp");

        {
            let mut file = fs::File::create(&tmp_path)
                .map_err(|e| IoError::Io(e.to_string()))?;
            file.write_all(json.as_bytes())
                .map_err(|e| IoError::Io(e.to_string()))?;
            file.sync_all()
                .map_err(|e| IoError::Io(e.to_string()))?;
        }

        fs::rename(&tmp_path, path)
            .map_err(|e| IoError::Io(e.to_string()))?;

        Ok(())
    }

    /// Load and deserialize a project from `path`.
    pub fn load(path: &Path) -> Result<NovaProject, IoError> {
        let json = fs::read_to_string(path)
            .map_err(|e| IoError::Io(e.to_string()))?;

        let project: NovaProject = serde_json::from_str(&json)
            .map_err(|e| IoError::Deserialize(e.to_string()))?;

        Ok(project)
    }

    /// Create a `.pre_migration.bak` backup before migrating.
    pub fn backup_before_migration(path: &Path) -> Result<PathBuf, IoError> {
        let bak_path = path.with_extension("pre_migration.bak");
        fs::copy(path, &bak_path)
            .map_err(|e| IoError::Io(e.to_string()))?;
        Ok(bak_path)
    }
}

// ---- Autosave ----

/// Manages rolling autosave snapshots for a project.
pub struct AutosaveManager {
    /// Directory where snapshots are stored: `<project>.autosave/`
    pub snapshot_dir: PathBuf,
    /// Maximum snapshots to retain.
    pub keep_count: u32,
}

impl AutosaveManager {
    pub fn new(project_path: &Path, keep_count: u32) -> Self {
        let dir = project_path
            .parent()
            .unwrap_or(Path::new("."))
            .join(format!(
                "{}.autosave",
                project_path.file_name().unwrap_or_default().to_string_lossy()
            ));
        Self { snapshot_dir: dir, keep_count }
    }

    /// Write an autosave snapshot. Returns the snapshot path.
    pub fn write_snapshot(&self, project: &NovaProject) -> Result<PathBuf, IoError> {
        fs::create_dir_all(&self.snapshot_dir)
            .map_err(|e| IoError::Io(e.to_string()))?;

        let timestamp = Utc::now().format("%Y%m%dT%H%M%SZ").to_string();
        let snap_path = self.snapshot_dir.join(format!("{}.nova", timestamp));

        ProjectIo::save(project, &snap_path)?;

        // Prune old snapshots
        self.prune_old_snapshots()?;

        Ok(snap_path)
    }

    /// List all snapshots, newest first.
    pub fn list_snapshots(&self) -> Result<Vec<PathBuf>, IoError> {
        if !self.snapshot_dir.exists() {
            return Ok(Vec::new());
        }

        let mut entries: Vec<PathBuf> = fs::read_dir(&self.snapshot_dir)
            .map_err(|e| IoError::Io(e.to_string()))?
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().map(|x| x == "nova").unwrap_or(false))
            .collect();

        // Sort newest first (lexicographic works since timestamps are ISO-formatted)
        entries.sort_by(|a, b| b.cmp(a));
        Ok(entries)
    }

    /// Write crash marker so recovery wizard knows to show on next launch.
    pub fn write_crash_marker(&self) -> Result<(), IoError> {
        fs::create_dir_all(&self.snapshot_dir)
            .map_err(|e| IoError::Io(e.to_string()))?;
        let marker = self.snapshot_dir.join("CRASH_MARKER");
        fs::write(&marker, Utc::now().to_rfc3339())
            .map_err(|e| IoError::Io(e.to_string()))?;
        Ok(())
    }

    /// Clear crash marker after clean shutdown or user dismiss.
    pub fn clear_crash_marker(&self) -> Result<(), IoError> {
        let marker = self.snapshot_dir.join("CRASH_MARKER");
        if marker.exists() {
            fs::remove_file(&marker)
                .map_err(|e| IoError::Io(e.to_string()))?;
        }
        Ok(())
    }

    /// Check if a crash marker exists (unclean previous shutdown).
    pub fn has_crash_marker(&self) -> bool {
        self.snapshot_dir.join("CRASH_MARKER").exists()
    }

    fn prune_old_snapshots(&self) -> Result<(), IoError> {
        let snapshots = self.list_snapshots()?;
        for old in snapshots.iter().skip(self.keep_count as usize) {
            let _ = fs::remove_file(old);
        }
        Ok(())
    }
}

// ---- Recovery ----

/// Recovery information presented to the UI Recovery Wizard.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecoveryInfo {
    pub snapshot_count: usize,
    pub snapshots: Vec<SnapshotInfo>,
    pub crash_marker_present: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SnapshotInfo {
    pub path: String,
    pub timestamp: String,
    pub size_bytes: u64,
}

impl RecoveryInfo {
    /// Collect recovery info for the recovery wizard.
    pub fn collect(manager: &AutosaveManager) -> Result<Self, IoError> {
        let crash_marker_present = manager.has_crash_marker();
        let snapshots_paths = manager.list_snapshots()?;

        let snapshots: Vec<SnapshotInfo> = snapshots_paths
            .iter()
            .map(|p| {
                let meta = fs::metadata(p).ok();
                SnapshotInfo {
                    path: p.to_string_lossy().to_string(),
                    timestamp: p
                        .file_stem()
                        .map(|s| s.to_string_lossy().to_string())
                        .unwrap_or_default(),
                    size_bytes: meta.map(|m| m.len()).unwrap_or(0),
                }
            })
            .collect();

        Ok(RecoveryInfo {
            snapshot_count: snapshots.len(),
            snapshots,
            crash_marker_present,
        })
    }
}

// ---- Error ----

#[derive(Debug, thiserror::Error)]
pub enum IoError {
    #[error("I/O error: {0}")]
    Io(String),
    #[error("Serialization error: {0}")]
    Serialize(String),
    #[error("Deserialization error: {0}")]
    Deserialize(String),
}
