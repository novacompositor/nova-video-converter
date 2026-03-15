import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../panels"

Item {
    id: root
    
    // Shared state between panels
    property string activeCompositionId: ""
    property string activeLayerId: ""
    property string activeLayerName: ""

    // AE Familiar layout with Resizable panels via SplitView
    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical

        handle: Rectangle {
            implicitHeight: 4
            color: "#2a2a38"
        }

        SplitView {
            SplitView.fillHeight: true
            SplitView.preferredHeight: parent.height * 0.65
            orientation: Qt.Horizontal

            handle: Rectangle {
                implicitWidth: 4
                color: "#2a2a38"
            }

            // ── LEFT: Project & Effect Controls ─────────────────────────
            SplitView {
                SplitView.preferredWidth: 300
                SplitView.minimumWidth: 200
                orientation: Qt.Vertical
                
                handle: Rectangle {
                    implicitHeight: 4
                    color: "#2a2a38"
                }

                ProjectPanel {
                    SplitView.fillHeight: true
                    SplitView.preferredHeight: 300
                    SplitView.minimumHeight: 150
                }

                EffectControlsPanel {
                    SplitView.fillHeight: true
                    SplitView.preferredHeight: 300
                    SplitView.minimumHeight: 150
                    
                    activeCompositionId: root.activeCompositionId
                    activeLayerId: root.activeLayerId
                    activeLayerName: root.activeLayerName
                }
            }

            // ── CENTER: Viewer ──────────────────────────────────────────
            ViewerPanel {
                SplitView.fillWidth: true
                SplitView.fillHeight: true
                SplitView.minimumWidth: 200
            }

            // ── RIGHT: Properties ───────────────────────────────────────
            PropertiesPanel {
                SplitView.preferredWidth: 320
                SplitView.minimumWidth: 200
                SplitView.fillHeight: true
            }
        }

        // ── BOTTOM: Timeline ────────────────────────────────────────────
        TimelinePanel {
            id: timelinePanel
            SplitView.fillWidth: true
            SplitView.preferredHeight: 300
            SplitView.minimumHeight: 150
            
            // Bind to CompositingRoom
            activeCompositionId: root.activeCompositionId
            onActiveCompositionIdChanged: root.activeCompositionId = activeCompositionId
            onActiveLayerIdChanged: {
                root.activeLayerId = activeLayerId;
                root.activeLayerName = activeLayerName;
            }
        }
    }
}
