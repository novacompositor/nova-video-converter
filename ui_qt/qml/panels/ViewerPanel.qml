import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Composition Viewer panel — center of the AE Familiar layout.
Rectangle {
    id: root
    color: "#0a0a0f"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Viewer toolbar
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: "#13131c"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                // Zoom control
                Text { text: "100%"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }

                Rectangle { width: 1; height: 18; color: "#2a2a38" }

                // FPS indicator
                Text { text: "24 fps"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }

                Rectangle { width: 1; height: 18; color: "#2a2a38" }

                // Resolution
                Text { text: "1920 × 1080"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }

                Item { Layout.fillWidth: true }

                // Safe margins toggle
                Text { text: "Safe"; color: "#555568"; font.pixelSize: 11; font.family: "Inter" }
                // Guides toggle
                Text { text: "Grid"; color: "#555568"; font.pixelSize: 11; font.family: "Inter" }
                // Alpha/RGB toggle
                Text { text: "RGB"; color: "#4a9eff"; font.pixelSize: 11; font.family: "Inter" }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2a2a38"
            }
        }

        // Canvas area
        Item {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true

            // The decoded frame from FFmpeg via Rust
            Image {
                id: videoFrame
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.9
                fillMode: Image.PreserveAspectFit
                cache: false // Force QML to re-request frame when source changes
                // source: "image://videoframe/path/to/video.mp4" 
                // This will be bound to the EngineState later
            }

            // Composition frame border
            Rectangle {
                id: compFrame
                anchors.centerIn: parent
                // 16:9 frame preview placeholder
                width: Math.min(parent.width - 60, (parent.height - 60) * 16 / 9)
                height: width * 9 / 16
                color: "black"
                border.color: "#3a3a52"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "No Composition Open"
                    color: "#3a3a52"
                    font.pixelSize: 16
                    font.family: "Inter"
                }
            }
        }

        // Playback toolbar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#13131c"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2a2a38"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // Go to start
                Text { text: "⏮"; color: "#8888a0"; font.pixelSize: 16 }
                // Step back
                Text { text: "◀"; color: "#8888a0"; font.pixelSize: 14 }
                // Play/Pause
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: "#4a9eff"
                    Text { anchors.centerIn: parent; text: "▶"; color: "white"; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: {} /* TODO: StartPlayback */ }
                }
                // Step forward
                Text { text: "▶"; color: "#8888a0"; font.pixelSize: 14 }
                // Go to end
                Text { text: "⏭"; color: "#8888a0"; font.pixelSize: 16 }

                Item { Layout.fillWidth: true }

                // Timecode
                Rectangle {
                    width: 110; height: 24
                    color: "#0f0f14"
                    border.color: "#2a2a38"
                    border.width: 1
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: "00:00:00:00"
                        color: "#4a9eff"
                        font.pixelSize: 13
                        font.family: "Inter"
                        font.letterSpacing: 1.5
                    }
                }
            }
        }
    }
}
