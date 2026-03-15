import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Workspace switcher bar: AE Familiar | Animation | Compositing | Color | Text
Rectangle {
    id: root
    height: 28
    color: "#0d0d12"

    property string activeWorkspace: "Compositing"
    readonly property var workspaces: [
        "Edit", "Compositing", "Node Graph", "Color", "Keying", 
        "3D Scene", "Tracking", "Rigging", "AI Video", 
        "Particles", "Motion Packs"
    ]

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        spacing: 0

        Text {
            text: "Workspace:"
            color: "#4a4a60"
            font.pixelSize: 10
            font.family: "Inter"
            Layout.rightMargin: 8
        }

        Repeater {
            model: root.workspaces
            delegate: Rectangle {
                property bool isActive: modelData === root.activeWorkspace
                height: 28
                implicitWidth: wsLabel.implicitWidth + 20
                color: "transparent"

                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    text: modelData
                    color: isActive ? "#4a9eff" : "#6a6a82"
                    font.pixelSize: 11
                    font.family: "Inter"
                }

                Rectangle {
                    visible: isActive
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: "#4a9eff"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.activeWorkspace = modelData
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#2a2a38"
    }
}
