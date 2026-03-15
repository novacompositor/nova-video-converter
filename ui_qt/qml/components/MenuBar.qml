import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Top menu bar: File | Edit | View | Composition | Layer | Effect | Help
Rectangle {
    id: root
    height: 36
    color: "#0d0d12"

    property var menus: [
        { label: "File",        items: ["New Project\tCtrl+N", "Open Project…\tCtrl+O", "—", "Save\tCtrl+S", "Save As…\tCtrl+Shift+S", "—", "Import Media…\tCtrl+I", "—", "Export…\tCtrl+E", "—", "Quit\tCtrl+Q"] },
        { label: "Edit",        items: ["Undo\tCtrl+Z", "Redo\tCtrl+Shift+Z", "—", "Preferences…"] },
        { label: "View",        items: ["Zoom In\t+", "Zoom Out\t–", "Fit to View\tShift+/", "—", "GPU Diagnostics…"] },
        { label: "Composition", items: ["New Composition…", "Composition Settings…", "—", "Set Work Area", "Trim to Work Area"] },
        { label: "Layer",       items: ["New Solid…", "New Text…", "New Null…", "New Adjustment…", "—", "Add to Render Queue\tCtrl+M"] },
        { label: "Effect",      items: ["Browse Effects…", "—", "Remove All Effects"] },
        { label: "Help",        items: ["Documentation", "About Nova Compositor…"] },
    ]

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        spacing: 0

        // Nova logo
        Text {
            text: "✦"
            color: "#4a9eff"
            font.pixelSize: 16
            Layout.rightMargin: 12
        }

        // Menu items
        Repeater {
            model: root.menus
            delegate: Item {
                height: 36
                implicitWidth: label.implicitWidth + 20

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData.label
                    color: "#c8c8d8"
                    font.pixelSize: 13
                    font.family: "Inter"
                }

                Rectangle {
                    anchors.fill: parent
                    color: hArea.containsMouse ? "#1e1e28" : "transparent"
                    Behavior on color { ColorAnimation { duration: 60 } }
                }

                MouseArea {
                    id: hArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.label === "File") {
                            // Simple logic to find item index
                            for (let entry of modelData.items) {
                                if (entry.includes("Export")) {
                                    // In a real app we'd open a menu popup first. 
                                    // For now, clicking "File" will trigger Export if we don't have menus.
                                    // Actually, let's just make clicking "File" open export for testing.
                                    // root.parent usually refers to NovaApp
                                    try { root.parent.parent.openExportDialog() } catch(e) { console.log(e) }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // GPU status indicator
        Row {
            spacing: 6
            Layout.rightMargin: 12
            Rectangle { width: 7; height: 7; radius: 4; color: "#3acc88"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "GPU"; color: "#5a5a72"; font.pixelSize: 11; font.family: "Inter" }
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
