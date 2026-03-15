use thiserror::Error;

#[derive(Error, Debug)]
pub enum MediaImageError {
    #[error("Failed to read file: {0}")]
    IoError(#[from] std::io::Error),
    
    #[error("Image format error: {0}")]
    ImageError(#[from] image::ImageError),
    
    #[error("Failed to parse SVG: {0}")]
    SvgParseError(#[from] usvg::Error),
    
    #[error("Unsupported format")]
    UnsupportedFormat,
    
    #[error("Other error: {0}")]
    Other(String),
}
