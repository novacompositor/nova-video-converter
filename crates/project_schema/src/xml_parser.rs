use std::str::FromStr;
use roxmltree::Document;
use uuid::Uuid;
use engine_api::types::{Resolution, FrameRate, RationalTime};
use crate::sequence::{Sequence, Track, TrackKind, Clip, ClipItem};
use crate::asset::AssetKind;

#[derive(Debug, thiserror::Error)]
pub enum XmlParseError {
    #[error("Failed to parse XML: {0}")]
    ParseError(#[from] roxmltree::Error),
    #[error("Missing required attribute: {0}")]
    MissingAttribute(String),
    #[error("Invalid time format: {0}")]
    InvalidTime(String),
}

/// Parses a Final Cut Pro XML (FCPXML) string into our internal `Sequence`.
pub fn parse_fcpxml_sequence(xml_content: &str) -> Result<Sequence, XmlParseError> {
    let opt = roxmltree::ParsingOptions {
        allow_dtd: true,
        ..Default::default()
    };
    let doc = Document::parse_with_options(xml_content, opt)?;
    
    // Find the primary sequence tag
    let sequence_node = doc.descendants()
        .find(|n| n.has_tag_name("sequence"))
        .ok_or_else(|| XmlParseError::MissingAttribute("sequence tag".to_string()))?;

    // We assume 1920x1080 30fps for this MVP if not specified in FCPXML
    let sequence = Sequence::new(
        "Imported FCPXML Sequence", 
        Resolution { width: 1920, height: 1080 }, 
        FrameRate::new(30, 1)
    );

    let mut parsed_sequence = sequence;

    // Traverse the spine (main video track in FCPX)
    if let Some(spine) = sequence_node.descendants().find(|n| n.has_tag_name("spine")) {
        let mut main_video_track = Track::new("V1", TrackKind::Video);
        
        for clip_node in spine.children().filter(|n| n.is_element()) {
            let name = clip_node.attribute("name").unwrap_or("Untitled Clip").to_string();
            let start = parse_apple_time(clip_node.attribute("offset").unwrap_or("0s"))?;
            let duration = parse_apple_time(clip_node.attribute("duration").unwrap_or("0s"))?;
            let source_in = parse_apple_time(clip_node.attribute("start").unwrap_or("0s"))?;
            
            // Generate a dummy asset ID for MVP
            let asset_id = Uuid::new_v4();
            
            let clip = Clip::new_asset(
                name,
                asset_id,
                AssetKind::Video,
                start,
                source_in,
                duration
            );
            
            main_video_track.clips.push(clip);
        }

        parsed_sequence.video_tracks.push(main_video_track);
    }
    
    Ok(parsed_sequence)
}

/// Helper to parse Apple's relative time format (e.g. "10s", "1001/30000s")
fn parse_apple_time(time_str: &str) -> Result<RationalTime, XmlParseError> {
    let num_str = time_str.trim_end_matches('s');
    if num_str.contains('/') {
        let parts: Vec<&str> = num_str.split('/').collect();
        if parts.len() == 2 {
            let num: i64 = parts[0].parse().map_err(|_| XmlParseError::InvalidTime(time_str.to_string()))?;
            let den: u32 = parts[1].parse().map_err(|_| XmlParseError::InvalidTime(time_str.to_string()))?;
            return Ok(RationalTime::new(num, den));
        }
    } else {
        let secs: i64 = num_str.parse().map_err(|_| XmlParseError::InvalidTime(time_str.to_string()))?;
        return Ok(RationalTime::new(secs, 1));
    }
    Err(XmlParseError::InvalidTime(time_str.to_string()))
}
