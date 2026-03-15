import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import NovaCompositor

/// Toolbar containing the main AE-like tools
Rectangle {
    id: root
    color: "#161620"
    height: 36

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        // ── Main Tools ────────────────────────────
        Repeater {
            model: [
                { name: "Home", icon: "🏠" },
                { name: "Selection (V)", icon: "↖" },
                { name: "Hand (H)", icon: "✋" },
                { name: "Zoom (Z)", icon: "🔍" },
                { name: "Rotation (W)", icon: "↻" },
                { name: "Camera (C)", icon: "🎥" },
                { name: "Pan Behind (Y)", icon: "⌖" },
                { name: "Rectangle (Q)", icon: "⬜" },
                { name: "Pen (G)", icon: "✒" },
                { name: "Text (Ctrl+T)", icon: "T" },
                { name: "Brush (Ctrl+B)", icon: "🖌" },
                { name: "Clone Stamp (Ctrl+B)", icon: "⎘" },
                { name: "Eraser (Ctrl+B)", icon: "▱" },
                { name: "Roto Brush (Alt+W)", icon: "✂" },
                { name: "Puppet Pin (Ctrl+P)", icon: "📌" }
            ]
            
            Rectangle {
                width: 28
                height: 28
                color: toolArea.containsMouse ? "#2d333b" : "transparent"
                radius: 4
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: index === 1 ? "#4a9eff" : "#8888a0" // Selection tool active by default
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: toolArea
                    anchors.fill: parent
                    hoverEnabled: true
                    ToolTip.visible: containsMouse
                    ToolTip.text: modelData.name
                }
            }
        }
        
        Rectangle { width: 1; height: 20; color: "#2a2a38"; Layout.leftMargin: 4; Layout.rightMargin: 4 }
        
        // ── Fill / Stroke placeholders ────────────
        Text { text: "Fill:"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
        Rectangle { width: 16; height: 16; color: "#ff0000"; border.color: "#8888a0"; border.width: 1 }
        Text { text: "Stroke:"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter"; Layout.leftMargin: 8 }
        Rectangle { width: 16; height: 16; color: "transparent"; border.color: "#8888a0"; border.width: 2 }
        
        Item { Layout.fillWidth: true } // spacer
        
        // ── Right side info ────────────────────────
        Text { text: "Snapping"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
    }
    
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#2a2a38"
    }
}
