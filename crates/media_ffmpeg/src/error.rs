/// FFmpeg integration errors.
#[derive(Debug, thiserror::Error)]
pub enum FfmpegError {
    #[error("FFmpeg init failed: {0}")]
    InitFailed(String),
    #[error("Failed to open file: {0}")]
    OpenFailed(String),
    #[error("Codec error: {0}")]
    CodecError(String),
    #[error("Decode error: {0}")]
    DecodeError(String),
    #[error("Software scaler error: {0}")]
    ScalerError(String),
    #[error("No video stream found in file")]
    NoVideoStream,
    #[error("No audio stream found in file")]
    NoAudioStream,
    #[error("No frame was decoded from file")]
    NoFrameDecoded,
    #[error("FFmpeg not available: {0}")]
    NotAvailable(String),
    #[error("Encode error: {0}")]
    EncodeError(String),
    #[error("FFmpeg binary not found: {0}")]
    BinaryNotFound(String),
    #[error("Scene detection failed: {0}")]
    SceneDetectError(String),
}
