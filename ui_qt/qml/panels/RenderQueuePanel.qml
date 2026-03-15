import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import NovaCompositor

/// Render Queue panel — bottom-right.
Rectangle {
    color: "#161620"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader { title: "Render Queue" }

        // Render queue list placeholder
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "Queue is empty"
                color: "#3a3a50"
                font.pixelSize: 12
                font.family: "Inter"
            }
        }

        // Add to render queue button
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#13131c"
            border.color: "#2a2a38"
            border.width: 0

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2a2a38"
            }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text { text: "▶"; color: "#3acc88"; font.pixelSize: 12 }
                Text {
                    text: "Export..."
                    color: "#3acc88"
                    font.pixelSize: 12
                    font.family: "Inter"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: exportDialog.open()
            }
        }
    }

    ExportDialog {
        id: exportDialog
    }
}
