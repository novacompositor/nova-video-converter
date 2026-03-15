import QtQuick
import QtQuick.Controls.Basic

/// Reusable Nova-styled button.
Rectangle {
    id: root

    property string text: "Button"
    property color accentColor: "#4a9eff"
    property bool primary: false
    property bool enabled: true

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30
    radius: 4

    color: {
        if (!root.enabled) return "#1e1e28"
        if (hArea.pressed) return root.primary ? Qt.darker(root.accentColor, 1.2) : "#2a2a38"
        if (hArea.containsMouse) return root.primary ? Qt.darker(root.accentColor, 1.1) : "#252532"
        return root.primary ? root.accentColor : "#1e1e28"
    }

    border.color: root.primary ? "transparent" : "#3a3a50"
    border.width: 1

    Behavior on color { ColorAnimation { duration: 80 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.enabled
            ? (root.primary ? "white" : "#c8c8d8")
            : "#4a4a60"
        font.pixelSize: 12
        font.family: "Inter"
    }

    MouseArea {
        id: hArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }
}
