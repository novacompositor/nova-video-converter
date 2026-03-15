use std::path::Path;
use crate::error::MediaImageError;

#[derive(Debug, Clone, PartialEq)]
pub enum ImageKind {
    Raster,       // PNG, JPG, WEBP
    VectorSvg,    // SVG
    PhotoshopPsd, // PSD
}

#[derive(Debug, Clone)]
pub struct ImageInfo {
    pub path: String,
    pub width: u32,
    pub height: u32,
    pub has_alpha: bool,
    pub kind: ImageKind,
}

pub fn probe_image(path: &Path) -> Result<ImageInfo, MediaImageError> {
    let ext = path.extension().unwrap_or_default().to_string_lossy().to_lowercase();
    
    match ext.as_str() {
        "svg" => {
            let svg_data = std::fs::read(&path)?;
            let opt = usvg::Options::default();
            // usvg 0.43 parse
            let tree = usvg::Tree::from_data(&svg_data, &opt)?;
            let size = tree.size();
            
            Ok(ImageInfo {
                path: path.to_string_lossy().to_string(),
                width: size.width() as u32,
                height: size.height() as u32,
                has_alpha: true, // SVG inherently supports alpha
                kind: ImageKind::VectorSvg,
            })
        },
        "psd" => {
            let psd_data = std::fs::read(&path)?;
            let psd = psd::Psd::from_bytes(&psd_data).map_err(|e| MediaImageError::Other(e.to_string()))?;
            
            Ok(ImageInfo {
                path: path.to_string_lossy().to_string(),
                width: psd.width(),
                height: psd.height(),
                has_alpha: true,
                kind: ImageKind::PhotoshopPsd,
            })
        },
        _ => {
            // Let `image` crate figure it out (PNG, JPG, etc.)
            let reader = image::io::Reader::open(path)?.with_guessed_format()?;
            let format = reader.format().ok_or(MediaImageError::UnsupportedFormat)?;
            
            let dimensions = reader.into_dimensions()?;
            let has_alpha = match format {
                image::ImageFormat::Png | image::ImageFormat::WebP | image::ImageFormat::Tiff | image::ImageFormat::Gif => true,
                _ => false, // JPEG typically no alpha
            };
            
            Ok(ImageInfo {
                path: path.to_string_lossy().to_string(),
                width: dimensions.0,
                height: dimensions.1,
                has_alpha,
                kind: ImageKind::Raster,
            })
        }
    }
}
