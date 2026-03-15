import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Status bar — displayed at the very bottom of the window.
Rectangle {
    height: 22
    color: "#0a0a10"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Text { text: "Ready"; color: "#5a5a72"; font.pixelSize: 10; font.family: "Inter" }

        Rectangle { width: 1; height: 12; color: "#2a2a38" }

        Text { text: "No project"; color: "#4a4a60"; font.pixelSize: 10; font.family: "Inter" }

        Item { Layout.fillWidth: true }

        // Warn if GPU fallback
        Text { text: ""; color: "#f0c040"; font.pixelSize: 10; font.family: "Inter"; visible: false }

        Text { text: "Engine v" + APP_VERSION; color: "#3a3a52"; font.pixelSize: 10; font.family: "Inter" }

        Rectangle { width: 1; height: 12; color: "#2a2a38" }

        Text { text: "⚡ GPU Ready"; color: "#3acc88"; font.pixelSize: 10; font.family: "Inter" }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#2a2a38"
    }
}
