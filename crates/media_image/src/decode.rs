use crate::error::MediaImageError;
use crate::probe::{probe_image, ImageKind};
use std::path::Path;
use tiny_skia::Pixmap;
use usvg::{Options, Tree};

/// A decoded image frame (RGBA8, packed).
#[derive(Debug, Clone)]
pub struct ImageFrame {
    pub width: u32,
    pub height: u32,
    /// Raw RGBA pixels, width × height × 4 bytes.
    pub data: Vec<u8>,
}

pub fn decode_image(path: &Path) -> Result<ImageFrame, MediaImageError> {
    let info = probe_image(path)?;

    match info.kind {
        ImageKind::VectorSvg => {
            let svg_data = std::fs::read(path)?;
            let opt = Options::default();
            let tree = Tree::from_data(&svg_data, &opt)?;

            // For MVP we render SVG at its natural viewBox size.
            // Later we can pass requested width/height for infinite scaling.
            let size = tree.size();
            let w = size.width() as u32;
            let h = size.height() as u32;

            let mut pixmap = Pixmap::new(w, h)
                .ok_or_else(|| MediaImageError::Other("Failed to create skia pixmap".into()))?;

            resvg::render(&tree, tiny_skia::Transform::default(), &mut pixmap.as_mut());

            // resvg produces premultiplied RGBA (which is actually what we want for compositing!)
            Ok(ImageFrame {
                width: w,
                height: h,
                data: pixmap.take(),
            })
        }
        ImageKind::PhotoshopPsd => {
            let psd_data = std::fs::read(path)?;
            let psd = psd::Psd::from_bytes(&psd_data)
                .map_err(|e| MediaImageError::Other(e.to_string()))?;

            let w = psd.width();
            let h = psd.height();

            // psd crate returns flattened RGBA image
            let data = psd.rgba();

            Ok(ImageFrame {
                width: w,
                height: h,
                data,
            })
        }
        ImageKind::Raster => {
            // Standard image crate
            let img = image::ImageReader::open(path)?
                .with_guessed_format()?
                .decode()?;

            // Force conversion to RGBA8 for compositing pipeline
            let rgba_img = img.to_rgba8();
            let (w, h) = rgba_img.dimensions();

            Ok(ImageFrame {
                width: w,
                height: h,
                data: rgba_img.into_raw(),
            })
        }
    }
}
