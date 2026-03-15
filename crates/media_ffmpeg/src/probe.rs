use std::path::Path;
use std::collections::HashMap;
use crate::error::FfmpegError;

/// Aggregated information about a media file.
#[derive(Debug, Clone)]
pub struct MediaInfo {
    pub path: String,
    pub format_name: String,
    pub duration_ms: Option<u64>,
    pub bit_rate: Option<u64>,
    pub streams: Vec<StreamInfo>,
    pub metadata: HashMap<String, String>,
}

impl MediaInfo {
    /// Best video stream in the file, if any.
    pub fn best_video(&self) -> Option<&StreamInfo> {
        self.streams.iter().find(|s| matches!(s.kind, StreamKind::Video { .. }))
    }

    /// Best audio stream in the file, if any.
    pub fn best_audio(&self) -> Option<&StreamInfo> {
        self.streams.iter().find(|s| matches!(s.kind, StreamKind::Audio { .. }))
    }
}

/// Information about a single stream within a media file.
#[derive(Debug, Clone)]
pub struct StreamInfo {
    pub index: u32,
    pub codec_name: String,
    pub kind: StreamKind,
    pub time_base_num: i32,
    pub time_base_den: i32,
    pub duration_ts: Option<i64>,
}

/// Stream kind: video or audio.
#[derive(Debug, Clone)]
pub enum StreamKind {
    Video {
        width: u32,
        height: u32,
        fps_num: u32,
        fps_den: u32,
        pixel_format: String,
    },
    Audio {
        sample_rate: u32,
        channels: u32,
        sample_format: String,
    },
    Data,
    Subtitle,
}

/// Probe a media file and return its `MediaInfo`.
///
/// # Feature flag
/// Requires the `ffmpeg` feature (default). Without it, returns a stub error.
pub fn probe(path: &Path) -> Result<MediaInfo, FfmpegError> {
    #[cfg(feature = "ffmpeg")]
    {
        probe_impl(path)
    }
    #[cfg(not(feature = "ffmpeg"))]
    {
        Err(FfmpegError::NotAvailable("FFmpeg feature not compiled".into()))
    }
}

#[cfg(feature = "ffmpeg")]
fn probe_impl(path: &Path) -> Result<MediaInfo, FfmpegError> {
    use ffmpeg_next as ffmpeg;

    ffmpeg::init().map_err(|e| FfmpegError::InitFailed(e.to_string()))?;

    let input = ffmpeg::format::input(&path)
        .map_err(|e| FfmpegError::OpenFailed(e.to_string()))?;

    let format_name = input.format().name().to_owned();

    let duration_ms = if input.duration() > 0 {
        // FFmpeg duration is in AV_TIME_BASE units (microseconds)
        Some((input.duration() as u64) / 1000)
    } else {
        None
    };

    let bit_rate = if input.bit_rate() > 0 {
        Some(input.bit_rate() as u64)
    } else {
        None
    };

    let mut streams = Vec::new();
    for stream in input.streams() {
        let codec_params = stream.parameters();
        use ffmpeg_next::codec::Id;
        use ffmpeg_next::media::Type;

        let kind = match stream.parameters().medium() {
            Type::Video => {
                let decoder = ffmpeg_next::codec::context::Context::from_parameters(codec_params)
                    .map_err(|e| FfmpegError::CodecError(e.to_string()))?;
                let video = decoder.decoder().video()
                    .map_err(|e| FfmpegError::CodecError(e.to_string()))?;

                let avg_fr = stream.avg_frame_rate();
                StreamKind::Video {
                    width: video.width(),
                    height: video.height(),
                    fps_num: avg_fr.0 as u32,
                    fps_den: avg_fr.1 as u32,
                    pixel_format: format!("{:?}", video.format()),
                }
            }
            Type::Audio => {
                let decoder = ffmpeg_next::codec::context::Context::from_parameters(codec_params)
                    .map_err(|e| FfmpegError::CodecError(e.to_string()))?;
                let audio = decoder.decoder().audio()
                    .map_err(|e| FfmpegError::CodecError(e.to_string()))?;
                StreamKind::Audio {
                    sample_rate: audio.rate(),
                    channels: audio.channels() as u32,
                    sample_format: format!("{:?}", audio.format()),
                }
            }
            _ => StreamKind::Data,
        };

        let tb = stream.time_base();
        let codec_name = ffmpeg_next::codec::context::Context::from_parameters(stream.parameters())
            .ok()
            .and_then(|ctx| ctx.codec().map(|c| c.name().to_owned()))
            .unwrap_or_default();

        streams.push(StreamInfo {
            index: stream.index() as u32,
            codec_name,
            kind,
            time_base_num: tb.0,
            time_base_den: tb.1,
            duration_ts: if stream.duration() > 0 { Some(stream.duration()) } else { None },
        });
    }

    let mut metadata = HashMap::new();
    for (k, v) in input.metadata().iter() {
        metadata.insert(k.to_owned(), v.to_owned());
    }

    Ok(MediaInfo {
        path: path.to_string_lossy().to_string(),
        format_name,
        duration_ms,
        bit_rate,
        streams,
        metadata,
    })
}
