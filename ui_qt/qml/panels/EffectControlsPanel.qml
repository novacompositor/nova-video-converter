import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import NovaCompositor

/// Effect Controls panel — right column, top section.
Rectangle {
    id: root
    color: "#161620"

    property string activeCompositionId: ""
    property string activeLayerId: ""
    property string activeLayerName: ""
    
    // State for animated properties (mockup)
    property bool positionAnimated: false
    property bool opacityAnimated: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader { title: "Effect Controls" }

        // No layer selected placeholder
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeLayerId === ""

            Text {
                anchors.centerIn: parent
                text: "Select a layer to\nview its properties"
                horizontalAlignment: Text.AlignHCenter
                color: "#3a3a50"
                font.pixelSize: 12
                font.family: "Inter"
                lineHeight: 1.6
            }
        }
        
        // Active layer properties
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeLayerId !== ""
            clip: true
            
            ColumnLayout {
                width: parent.width - 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                
                Item { height: 8 } // top padding
                
                Text {
                    text: root.activeLayerName
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "Inter"
                }
                
                Rectangle { height: 1; Layout.fillWidth: true; color: "#2a2a38" }
                
                // Transform Group
                Text {
                    text: "▶ Transform"
                    color: "#a0a0b8"
                    font.pixelSize: 12
                    font.family: "Inter"
                }
                
                // Position X Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Rectangle {
                        width: 16; height: 16
                        color: "transparent"
                        Text { 
                            anchors.centerIn: parent
                            text: "⏱️" 
                            color: root.positionAnimated ? "#4a9eff" : "#555"
                            font.pixelSize: 12
                            opacity: root.positionAnimated ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.positionAnimated = !root.positionAnimated
                        }
                    }
                    
                    Text { text: "Position X"; color: "#8888a0"; font.pixelSize: 11; font.family: "Inter"; Layout.preferredWidth: 60 }
                    
                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 1920; value: 960
                        onValueChanged: {
                            if (!pressed || root.activeCompositionId === "") return;
                            
                            let cmdType = root.positionAnimated ? "AddKeyframe" : "SetPropertyValue";
                            let cmdPayload = {
                                type: cmdType,
                                composition_id: root.activeCompositionId,
                                layer_id: root.activeLayerId,
                                property_path: "transform.position",
                                value: { "Vec2": { "x": value, "y": 540.0 } },
                                time: { "num": 0, "den": 30 } // Using frame 0 for mockup
                            };
                            
                            if (root.positionAnimated) {
                                cmdPayload.interpolation = "Linear";
                            }

                            appBridge.dispatchCommand(JSON.stringify(cmdPayload));
                        }
                    }
                }
                
                // Opacity Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Rectangle {
                        width: 16; height: 16
                        color: "transparent"
                        Text { 
                            anchors.centerIn: parent
                            text: "⏱️" 
                            color: root.opacityAnimated ? "#4a9eff" : "#555"
                            font.pixelSize: 12
                            opacity: root.opacityAnimated ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.opacityAnimated = !root.opacityAnimated
                        }
                    }
                    
                    Text { text: "Opacity"; color: "#8888a0"; font.pixelSize: 11; font.family: "Inter"; Layout.preferredWidth: 60 }
                    
                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 100; value: 100
                        onValueChanged: {
                            if (!pressed || root.activeCompositionId === "") return;
                            
                            let cmdType = root.opacityAnimated ? "AddKeyframe" : "SetPropertyValue";
                            let cmdPayload = {
                                type: cmdType,
                                composition_id: root.activeCompositionId,
                                layer_id: root.activeLayerId,
                                property_path: "transform.opacity",
                                value: { "Float": value },
                                time: { "num": 0, "den": 30 } // Using frame 0 for mockup
                            };
                            
                            if (root.opacityAnimated) {
                                cmdPayload.interpolation = "Linear";
                            }

                            appBridge.dispatchCommand(JSON.stringify(cmdPayload));
                        }
                    }
                }
                
                Item { Layout.fillHeight: true } // spacer
            }
        }
    }
}
