//! media_ffmpeg — FFmpeg integration for media ingest and export.
//! Uses the `ffmpeg-next` crate which wraps libavcodec/avformat/avutil.

pub mod probe;
pub mod decode;
pub mod encode;
pub mod error;

pub use probe::{MediaInfo, StreamInfo, StreamKind};
pub use decode::{VideoFrame, AudioBuffer};
pub use encode::{encode_gif, split_by_scenes, ConvertOptions};
pub use error::FfmpegError;
