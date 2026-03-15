use media_ffmpeg::encode::split_by_scenes;
use std::path::PathBuf;

#[test]
fn test_scene_split_stub() {
    let input = PathBuf::from("non_existent.mp4");
    let output_dir = PathBuf::from("/tmp");
    
    let result = split_by_scenes(&input, &output_dir, 0.3);
    
    assert!(result.is_err());
}
