use project_schema::xml_parser::parse_fcpxml_sequence;

#[test]
fn test_parse_basic_fcpxml() {
    let xml = r#"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>
<fcpxml version="1.9">
    <resources>
        <format id="r1" frameDuration="1001/30000s" width="1920" height="1080"/>
    </resources>
    <library>
        <event name="Test Event">
            <project name="Test Project">
                <sequence format="r1" duration="10s">
                    <spine>
                        <video name="Clip 1" offset="0s" start="2s" duration="5s" />
                        <video name="Clip 2" offset="5s" start="0s" duration="5s" />
                    </spine>
                </sequence>
            </project>
        </event>
    </library>
</fcpxml>"#;

    let sequence = parse_fcpxml_sequence(xml).expect("Failed to parse valid XML");
    
    assert_eq!(sequence.name, "Imported FCPXML Sequence");
    assert_eq!(sequence.video_tracks.len(), 1);
    
    let v1 = &sequence.video_tracks[0];
    assert_eq!(v1.name, "V1");
    // We expect two clips on the V1 track (spine)
    assert_eq!(v1.clips.len(), 2);
    
    assert_eq!(v1.clips[0].name, "Clip 1");
    // 5s duration
    assert_eq!(v1.clips[0].duration.value, 5);
    assert_eq!(v1.clips[0].duration.rate, 1);
    
    // 2s source_in (start attribute in FCPXML)
    assert_eq!(v1.clips[0].source_in.value, 2);
    assert_eq!(v1.clips[0].source_in.rate, 1);
}
