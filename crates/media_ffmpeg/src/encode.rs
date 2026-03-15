use crate::error::FfmpegError;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::process::Command;

/// Advanced options for conversion and export.
/// Mirrored from engine_api for crate independence if needed,
/// but usually used via engine_api.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct ConvertOptions {
    pub split_scenes: bool,
    pub scene_threshold: f32,
    pub gif_fps: u32,
    pub gif_width: u32,
    pub gif_colors: u32,
}

/// Encode a video file to high-quality GIF using palettegen/paletteuse filters.
pub fn encode_gif(
    input: &Path,
    output: &Path,
    options: &ConvertOptions,
) -> Result<(), FfmpegError> {
    let ffmpeg_bin = std::env::var("NOVA_FFMPEG_BIN").unwrap_or_else(|_| "ffmpeg".to_string());

    let fps = if options.gif_fps > 0 {
        options.gif_fps
    } else {
        15
    };
    let width = if options.gif_width > 0 {
        options.gif_width as i32
    } else {
        -1
    };
    let colors = if options.gif_colors > 0 {
        options.gif_colors
    } else {
        256
    };

    // 1. Generate palette
    let temp_dir = std::env::temp_dir();
    let palette_path = temp_dir.join(format!("palette_{}.png", uuid::Uuid::new_v4()));

    let palette_filter = format!(
        "fps={},scale={}:-1:flags=lanczos,palettegen=max_colors={}",
        fps, width, colors
    );

    let status = Command::new(&ffmpeg_bin)
        .args([
            "-i",
            &input.to_string_lossy(),
            "-vf",
            &palette_filter,
            "-y",
            &palette_path.to_string_lossy(),
        ])
        .status()
        .map_err(|e| FfmpegError::EncodeError(e.to_string()))?;

    if !status.success() {
        return Err(FfmpegError::EncodeError(
            "Failed to generate GIF palette".into(),
        ));
    }

    // 2. Use palette to generate GIF
    let use_filter = format!(
        "fps={},scale={}:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer",
        fps, width
    );

    let status = Command::new(&ffmpeg_bin)
        .args([
            "-i",
            &input.to_string_lossy(),
            "-i",
            &palette_path.to_string_lossy(),
            "-filter_complex",
            &use_filter,
            "-y",
            &output.to_string_lossy(),
        ])
        .status()
        .map_err(|e| FfmpegError::EncodeError(e.to_string()))?;

    // Cleanup palette
    let _ = std::fs::remove_file(palette_path);

    if !status.success() {
        return Err(FfmpegError::EncodeError("Failed to encode GIF".into()));
    }

    Ok(())
}

/// Split video into multiple files based on scene detection.
pub fn split_by_scenes(
    input: &Path,
    output_dir: &Path,
    threshold: f32,
) -> Result<Vec<PathBuf>, FfmpegError> {
    let ffmpeg_bin = std::env::var("NOVA_FFMPEG_BIN").unwrap_or_else(|_| "ffmpeg".to_string());

    // Pass 1: Detect timestamps
    let output = Command::new(&ffmpeg_bin)
        .args([
            "-i",
            &input.to_string_lossy(),
            "-vf",
            &format!("select='gt(scene,{})',showinfo", threshold),
            "-f",
            "null",
            "-",
        ])
        .output()
        .map_err(|e| FfmpegError::SceneDetectError(e.to_string()))?;

    if !output.status.success() {
        let err_msg = String::from_utf8_lossy(&output.stderr);
        return Err(FfmpegError::SceneDetectError(format!(
            "FFmpeg detection pass failed: {}",
            err_msg
        )));
    }

    let stderr = String::from_utf8_lossy(&output.stderr);
    let mut timestamps = Vec::new();

    for line in stderr.lines() {
        if line.contains("showinfo") && line.contains("pts_time:") {
            if let Some(pts_idx) = line.find("pts_time:") {
                let rest = &line[pts_idx + 9..];
                if let Some(space_idx) = rest.find(' ') {
                    if let Ok(ts) = rest[..space_idx].parse::<f32>() {
                        timestamps.push(ts);
                    }
                }
            }
        }
    }

    // Pass 2: Actual splitting
    let mut result_files = Vec::new();
    let file_ext = input.extension().and_then(|e| e.to_str()).unwrap_or("mp4");

    let mut start_time = 0.0;
    for (i, &end_time) in timestamps
        .iter()
        .chain(std::iter::once(&999999.0))
        .enumerate()
    {
        if end_time - start_time < 0.1 && i > 0 {
            continue;
        } // skip tiny segments

        let output_file = output_dir.join(format!("shot_{:04}.{}", i, file_ext));

        let mut cmd = Command::new(&ffmpeg_bin);
        cmd.args([
            "-ss",
            &start_time.to_string(),
            "-i",
            &input.to_string_lossy(),
        ]);

        if end_time < 999998.0 {
            cmd.args(["-to", &(end_time - start_time).to_string()]);
        }

        cmd.args(["-c", "copy", "-y", &output_file.to_string_lossy()]);

        let status = cmd
            .status()
            .map_err(|e| FfmpegError::EncodeError(e.to_string()))?;
        if status.success() {
            result_files.push(output_file);
        }

        if end_time > 999998.0 {
            break;
        }
        start_time = end_time;
    }

    Ok(result_files)
}
