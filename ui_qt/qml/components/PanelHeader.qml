import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Reusable panel header bar.
Rectangle {
    id: root
    height: 32
    color: "#13131c"

    property string title: "Panel"
    property alias extraContent: extraSlot.data

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 6

        Text {
            text: root.title.toUpperCase()
            color: "#9090aa"
            font.pixelSize: 10
            font.family: "Inter"
            font.letterSpacing: 1.2
            font.weight: Font.Medium
        }

        Item { Layout.fillWidth: true }

        Item {
            id: extraSlot
            Layout.fillHeight: true
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
