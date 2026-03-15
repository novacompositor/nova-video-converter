import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qt.labs.platform as Platform
import NovaCompositor

/// Export Settings Dialog.
Popup {
    id: root
    width: 480
    height: 520
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    
    background: Rectangle {
        color: "#1e1e28"
        radius: 8
        border.color: "#3a3a4d"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Text {
            text: "Export Settings"
            color: "white"
            font.pixelSize: 18
            font.bold: true
            font.family: "Inter"
        }

        // --- Output Path ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "Output Destination"; color: "#a0a0b0"; font.pixelSize: 12 }
            RowLayout {
                TextField {
                    id: outputPathField
                    Layout.fillWidth: true
                    placeholderText: "Select folder or file path..."
                    color: "white"
                    background: Rectangle { color: "#13131c"; border.color: "#2a2a38" }
                }
                Button {
                    text: "Browse..."
                    onClicked: folderPicker.open()
                }
            }
        }

        // --- Format ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "Format"; color: "#a0a0b0"; font.pixelSize: 12 }
            ComboBox {
                id: formatCombo
                Layout.fillWidth: true
                model: ["MP4 (H.264)", "MOV (ProRes)", "MKV", "GIF", "PNG Sequence"]
                currentIndex: 0
            }
        }

        // --- GIF Options (Visible only when GIF is selected) ---
        ColumnLayout {
            Layout.fillWidth: true
            visible: formatCombo.currentText === "GIF"
            spacing: 12
            
            RowLayout {
                ColumnLayout {
                    Text { text: "FPS"; color: "#a0a0b0"; font.pixelSize: 11 }
                    SpinBox { id: gifFps; from: 1; to: 60; value: 15 }
                }
                ColumnLayout {
                    Text { text: "Max Width"; color: "#a0a0b0"; font.pixelSize: 11 }
                    SpinBox { id: gifWidth; from: 0; to: 3840; value: 480; stepSize: 2 }
                }
                ColumnLayout {
                    Text { text: "Colours"; color: "#a0a0b0"; font.pixelSize: 11 }
                    SpinBox { id: gifColors; from: 2; to: 256; value: 256 }
                }
            }
        }

        // --- Scene Split ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            CheckBox {
                id: splitShotsCheck
                text: "Split into shots (Scene Detection)"
                font.family: "Inter"
                palette.windowText: "white"
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                visible: splitShotsCheck.checked
                spacing: 4
                RowLayout {
                    Text { text: "Sensitivity"; color: "#a0a0b0"; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    Text { text: (sceneThreshold.value / 100).toFixed(2); color: "white"; font.pixelSize: 11 }
                }
                Slider {
                    id: sceneThreshold
                    Layout.fillWidth: true
                    from: 1
                    to: 95
                    value: 30
                }
            }
        }

        Item { Layout.fillHeight: true }

        // --- Actions ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Button {
                text: "Cancel"
                Layout.fillWidth: true
                onClicked: root.close()
            }
            Button {
                text: "Export"
                Layout.fillWidth: true
                highlighted: true
                onClicked: {
                    let options = {
                        "split_scenes": splitShotsCheck.checked,
                        "scene_threshold": sceneThreshold.value / 100.0,
                        "gif_fps": gifFps.value,
                        "gif_width": gifWidth.value,
                        "gif_colors": gifColors.value
                    };

                    let preset = {
                        "name": formatCombo.currentText,
                        "format": formatCombo.currentText === "GIF" ? "Gif" : 
                                  formatCombo.currentText.includes("MP4") ? "Mp4" : "Mov",
                        "video_codec": formatCombo.currentText === "GIF" ? "gif" : "libx264",
                        "quality": "High"
                    };

                    let command = {
                        "type": "QueueRenderJob",
                        "payload": {
                            "composition_id": "00000000-0000-0000-0000-000000000000", // Placeholder
                            "output_path": outputPathField.text,
                            "preset": preset,
                            "options": options
                        }
                    };

                    appBridge.dispatchCommand(JSON.stringify(command));
                    root.close();
                }
            }
        }
    }

    Platform.FolderDialog {
        id: folderPicker
        title: "Choose output folder"
        onAccepted: {
            let path = folder.toString()
            // Cross-platform path cleanup
            if (Qt.platform.os === "windows") {
                path = path.replace("file:///", "").replace(/\//g, "\\")
            } else {
                path = path.replace("file://", "")
            }
            outputPathField.text = path
        }
    }
}
