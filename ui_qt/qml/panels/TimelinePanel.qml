import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Timeline panel — Layer stack + track lanes + playhead.
Rectangle {
    id: root
    color: "#161620"

    property string activeCompositionId: ""
    property string activeLayerId: ""
    property string activeLayerName: ""

    Component.onCompleted: {
        appBridge.dispatchCommand(JSON.stringify({ type: "SyncState" }));
    }

    Connections {
        target: appBridge
        function onEngineEventReceived(eventString) {
            try {
                let res = JSON.parse(eventString);
                if (res.status === "success" && res.events) {
                    for (let i = 0; i < res.events.length; i++) {
                        let ev = res.events[i];
                        if (ev.type === "ProjectChanged") {
                            // Rust state changed, sync it back
                            appBridge.dispatchCommand(JSON.stringify({ type: "SyncState" }));
                        } else if (ev.type === "StateSynced") {
                            let project = ev.payload.project;
                            if (project && project.compositions && project.compositions.length > 0) {
                                // For MVP we just pick the first composition
                                let comp = project.compositions[0];
                                root.activeCompositionId = comp.id;
                                
                                layerModel.clear();
                                for (let j = 0; j < comp.layers.length; j++) {
                                    let layer = comp.layers[j];
                                    let colorHex = "#4a4a60";
                                    if (layer.kind.type === "Solid" && layer.kind.color) {
                                        let c = layer.kind.color;
                                        colorHex = Qt.rgba(c[0], c[1], c[2], c[3]).toString();
                                    }
                                    layerModel.append({
                                        "id": layer.id,
                                        "name": layer.name,
                                        "color": colorHex
                                    });
                                }
                            }
                        }
                    }
                }
            } catch (e) {
                console.error("TimelinePanel error parsing event:", e);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Timeline toolbar
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#13131c"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Zoom in/out
                Text { text: "–"; color: "#8888a0"; font.pixelSize: 16 }
                Rectangle {
                    width: 80; height: 4; radius: 2
                    color: "#2a2a38"
                    Rectangle {
                        width: 32; height: parent.height; radius: 2
                        color: "#4a9eff"
                    }
                }
                Text { text: "+"; color: "#8888a0"; font.pixelSize: 16 }

                Rectangle { width: 1; height: 18; color: "#2a2a38" }

                Text { text: "Snapping"; color: "#4a9eff"; font.pixelSize: 11; font.family: "Inter" }

                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 80
                    height: 20
                    color: addLayerMouseArea.containsMouse ? "#4a9eff" : "#3a5a8a"
                    radius: 3
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Add Solid"
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.family: "Inter"
                        font.bold: true
                    }

                    MouseArea {
                        id: addLayerMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.activeCompositionId === "") {
                                console.warn("No active composition to add layer to");
                                return;
                            }
                            
                            // Send command to Rust
                            appBridge.dispatchCommand(JSON.stringify({
                                type: "AddLayer",
                                composition_id: root.activeCompositionId,
                                layer_type: { type: "Solid", color: [Math.random(), 0.5, 0.8, 1.0] },
                                name: "Solid Layer " + (layerModel.count + 1),
                                index: null
                            }));
                        }
                    }
                }

                Text { text: "00:00:00:00"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2a2a38"
            }
        }

        // Timeline body
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Layer names column
            Rectangle {
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                color: "#13131c"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Column header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: "#0f0f14"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            
                            Text {
                                text: "LAYERS"
                                color: "#5a5a72"
                                font.pixelSize: 9
                                font.letterSpacing: 1.5
                                font.family: "Inter"
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                text: "PARENT & LINK"
                                color: "#5a5a72"
                                font.pixelSize: 9
                                font.letterSpacing: 1.5
                                font.family: "Inter"
                                Layout.preferredWidth: 90
                            }
                        }
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: "#2a2a38"
                        }
                    }

                    // Layer ListModel
                    ListModel { id: layerModel }

                    ListView {
                        id: layerListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: layerModel
                        clip: true
                        
                        delegate: Rectangle {
                            width: layerListView.width
                            height: 28
                            color: index % 2 == 0 ? "transparent" : "#1e1e28"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 8
                                
                                Rectangle {
                                    width: 12; height: 12
                                    color: model.color
                                    radius: 2
                                }
                                
                                Text {
                                    text: model.name
                                    color: "#e8e8ea"
                                    font.pixelSize: 12
                                    font.family: "Inter"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                
                                // Mockup Parent Dropdown
                                Rectangle {
                                    Layout.preferredWidth: 90
                                    Layout.preferredHeight: 20
                                    color: "#2a2a38"
                                    radius: 3
                                    
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        text: "None"
                                        color: "#a0a0b8"
                                        font.pixelSize: 10
                                        font.family: "Inter"
                                    }
                                    
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        text: "▼"
                                        color: "#555566"
                                        font.pixelSize: 8
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onContainsMouseChanged: {
                                            parent.color = containsMouse ? "#3a3a48" : "#2a2a38"
                                        }
                                        onClicked: {
                                            // Mockup: in MVP we just console log
                                            console.log("Open Parent menu for layer: " + model.id);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: "#2a2a38"
                }
            }

            // Track lanes
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Ruler
                Rectangle {
                    id: ruler
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 28
                    color: "#0f0f14"

                    // Tick marks (placeholder)
                    Row {
                        anchors.fill: parent
                        spacing: 60

                        Repeater {
                            model: 20
                            delegate: Item {
                                width: 60; height: parent.height
                                Text {
                                    text: "0:" + String(index * 2).padStart(2, "0") + ":00"
                                    color: "#4a4a60"
                                    font.pixelSize: 10
                                    font.family: "Inter"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    anchors.left: parent.left
                                    anchors.leftMargin: 2
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    width: 1
                                    height: 8
                                    color: "#3a3a52"
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#2a2a38"
                    }
                }

                // Timeline Blocks (Clips/Solids)
                ListView {
                    id: timelineListView
                    anchors.top: ruler.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    model: layerModel
                    interactive: false // sync with layerListView later
                    clip: true
                    
                    delegate: Item {
                        width: timelineListView.width
                        height: 28
                        
                        Rectangle {
                            // Dummy layout: staggered start
                            x: 50 + (index * 20)
                            y: 4
                            width: 200
                            height: 20
                            color: model.color
                            opacity: 0.8
                            radius: 2
                            border.color: "#161620"
                            border.width: 1
                            
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                text: model.name
                                color: "#000000"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                        
                        // Mockup Keyframes (diamonds)
                        Repeater {
                            model: index % 2 === 0 ? 3 : 0 // Add dummy keyframes to some layers
                            
                            Rectangle {
                                width: 8; height: 8
                                color: "#aaddff"
                                rotation: 45
                                x: 60 + (index * 40) + (Math.random() * 20)
                                y: 10
                                border.color: "#161620"
                                border.width: 1
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    anchors.topMargin: 28
                    text: "Drop media here or create a new layer"
                    color: "#3a3a50"
                    font.pixelSize: 13
                    font.family: "Inter"
                    visible: layerModel.count === 0
                }

                // Playhead
                Rectangle {
                    id: playhead
                    x: 0
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: "#4a9eff"
                    opacity: 0.85

                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 10; height: 10
                        color: "#4a9eff"
                        rotation: 45
                        anchors.topMargin: -4
                    }
                }
            }
        }
    }
}
