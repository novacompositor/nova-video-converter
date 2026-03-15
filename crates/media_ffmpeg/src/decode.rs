use crate::error::FfmpegError;
use std::path::Path;

/// A decoded video frame (RGBA8, packed).
#[derive(Debug, Clone)]
pub struct VideoFrame {
    pub width: u32,
    pub height: u32,
    /// Raw RGBA pixels, width × height × 4 bytes.
    pub data: Vec<u8>,
    /// Presentation timestamp in stream timebase units.
    pub pts: i64,
}

/// A decoded audio buffer (interleaved f32 samples).
#[derive(Debug, Clone)]
pub struct AudioBuffer {
    pub channels: u32,
    pub sample_rate: u32,
    /// Interleaved f32 samples: [ch0_s0, ch1_s0, ..., ch0_s1, ch1_s1, ...]
    pub samples: Vec<f32>,
    pub pts: i64,
}

/// Decode the first video frame from `path` into a `VideoFrame`.
///
/// Requires the `ffmpeg` feature (default).
pub fn decode_first_frame(path: &Path) -> Result<VideoFrame, FfmpegError> {
    decode_frame_at(path, 0)
}

/// Decode the video frame at the specific `time_ms`.
pub fn decode_frame_at(path: &Path, time_ms: i64) -> Result<VideoFrame, FfmpegError> {
    #[cfg(feature = "ffmpeg")]
    {
        decode_frame_at_impl(path, time_ms)
    }
    #[cfg(not(feature = "ffmpeg"))]
    {
        Err(FfmpegError::NotAvailable(
            "FFmpeg feature not compiled".into(),
        ))
    }
}

#[cfg(feature = "ffmpeg")]
fn decode_frame_at_impl(path: &Path, time_ms: i64) -> Result<VideoFrame, FfmpegError> {
    use ffmpeg_next as ffmpeg;
    use ffmpeg_next::format::Pixel;
    use ffmpeg_next::media::Type;
    use ffmpeg_next::software::scaling::{context::Context as SwsContext, flag::Flags};
    use ffmpeg_next::util::frame::video::Video;

    ffmpeg::init().map_err(|e| FfmpegError::InitFailed(e.to_string()))?;

    let mut input =
        ffmpeg::format::input(&path).map_err(|e| FfmpegError::OpenFailed(e.to_string()))?;

    let video_stream = input
        .streams()
        .best(ffmpeg_next::media::Type::Video)
        .ok_or(FfmpegError::NoVideoStream)?;

    let video_stream_index = video_stream.index();
    let time_base = video_stream.time_base();
    let codec_params = video_stream.parameters();

    // Calculate target PTS
    let time_base_f64 = f64::from(time_base.numerator()) / f64::from(time_base.denominator());
    let target_pts = ((time_ms as f64 / 1000.0) / time_base_f64) as i64;

    // Seek to the target pts (keyframe before or at the target)
    let _ = input.seek(target_pts, ..target_pts);

    let decoder_ctx = ffmpeg_next::codec::context::Context::from_parameters(codec_params)
        .map_err(|e| FfmpegError::CodecError(e.to_string()))?;
    let mut decoder = decoder_ctx
        .decoder()
        .video()
        .map_err(|e| FfmpegError::CodecError(e.to_string()))?;

    let src_w = decoder.width();
    let src_h = decoder.height();
    let src_fmt = decoder.format();

    let mut scaler = SwsContext::get(
        src_fmt,
        src_w,
        src_h,
        Pixel::RGBA,
        src_w,
        src_h,
        Flags::BILINEAR,
    )
    .map_err(|e| FfmpegError::ScalerError(e.to_string()))?;

    let mut frame_yuv = Video::empty();
    let mut frame_rgba = Video::empty();

    for (stream, packet) in input.packets() {
        if stream.index() != video_stream_index {
            continue;
        }
        decoder
            .send_packet(&packet)
            .map_err(|e| FfmpegError::DecodeError(e.to_string()))?;

        while decoder.receive_frame(&mut frame_yuv).is_ok() {
            let pts = frame_yuv.pts().unwrap_or(0);

            // Wait until we reach the target PTS (or close enough)
            if pts >= target_pts || time_ms == 0 {
                scaler
                    .run(&frame_yuv, &mut frame_rgba)
                    .map_err(|e| FfmpegError::ScalerError(e.to_string()))?;

                let data = frame_rgba.data(0).to_vec();
                return Ok(VideoFrame {
                    width: src_w,
                    height: src_h,
                    data,
                    pts,
                });
            }
        }
    }

    // Fallback: if we didn't decode at target_pts (maybe it's at the end), we just fail for now
    Err(FfmpegError::NoFrameDecoded)
}
