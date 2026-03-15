use std::fmt;
use serde::{Deserialize, Serialize};

/// Structured engine error returned by command/query processing.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, thiserror::Error)]
pub struct EngineError {
    /// Machine-readable error code (e.g. "PROJECT_NOT_FOUND", "CODEC_UNSUPPORTED").
    pub code: EngineErrorCode,
    /// Human-readable description.
    pub message: String,
    /// Optional additional context (file path, layer id, etc.)
    pub context: Option<String>,
    /// Whether the application can continue after this error.
    pub recoverable: bool,
}

impl fmt::Display for EngineError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "[{}] {}", self.code, self.message)?;
        if let Some(ctx) = &self.context {
            write!(f, " (context: {})", ctx)?;
        }
        Ok(())
    }
}

impl EngineError {
    pub fn new(code: EngineErrorCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
            context: None,
            recoverable: true,
        }
    }

    pub fn with_context(mut self, ctx: impl Into<String>) -> Self {
        self.context = Some(ctx.into());
        self
    }

    pub fn unrecoverable(mut self) -> Self {
        self.recoverable = false;
        self
    }

    pub fn project_not_found(path: &str) -> Self {
        Self::new(EngineErrorCode::ProjectNotFound, format!("Project not found: {}", path))
            .with_context(path)
    }

    pub fn codec_unsupported(codec: &str) -> Self {
        Self::new(EngineErrorCode::CodecUnsupported, format!("Codec not supported: {}", codec))
            .with_context(codec)
    }

    pub fn asset_offline(path: &str) -> Self {
        Self::new(EngineErrorCode::AssetOffline, format!("Asset is offline: {}", path))
            .with_context(path)
    }

    pub fn gpu_error(reason: &str) -> Self {
        Self::new(EngineErrorCode::GpuError, format!("GPU error: {}", reason))
            .with_context(reason)
    }

    pub fn schema_version_mismatch(got: u32, expected: u32) -> Self {
        Self::new(
            EngineErrorCode::SchemaVersionMismatch,
            format!("Schema version mismatch: got {}, expected {}", got, expected),
        )
    }
}

/// Enumerated error codes for programmatic handling.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum EngineErrorCode {
    // Project
    ProjectNotFound,
    ProjectAlreadyOpen,
    ProjectSaveFailed,
    ProjectLoadFailed,
    SchemaVersionMismatch,
    MigrationFailed,

    // Asset / Media
    AssetOffline,
    AssetImportFailed,
    AssetLoadFailed,
    CodecUnsupported,
    MediaDecodeError,
    MediaEncodeError,

    // Render
    RenderFailed,
    RenderJobNotFound,
    ExportPathInvalid,

    // Timeline / Composition
    CompositionNotFound,
    LayerNotFound,
    KeyframeNotFound,
    InvalidTimeRange,

    // GPU / Render backend
    GpuError,
    GpuFallbackEngaged,
    ShaderCompilationFailed,

    // Bridge / API
    ApiVersionMismatch,
    CommandSerializationError,
    UnknownCommand,

    // I/O
    IoError,
    PermissionDenied,
    DiskFull,

    // Internal
    InternalError,
}

impl fmt::Display for EngineErrorCode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}", self)
    }
}

/// Convenience result type for engine operations.
pub type EngineResult<T> = Result<T, EngineError>;
