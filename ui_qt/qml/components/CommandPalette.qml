import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Command Palette — fuzzy-search all commands. Ctrl+Shift+P.
Rectangle {
    id: root
    width: 560
    height: 380
    radius: 8
    color: "#1a1a24"
    border.color: "#3a3a52"
    border.width: 1

    layer.enabled: true

    readonly property var allCommands: [
        { label: "File: New Project",            shortcut: "Ctrl+N" },
        { label: "File: Open Project",           shortcut: "Ctrl+O" },
        { label: "File: Save",                   shortcut: "Ctrl+S" },
        { label: "File: Import Media",           shortcut: "Ctrl+I" },
        { label: "Edit: Undo",                   shortcut: "Ctrl+Z" },
        { label: "Edit: Redo",                   shortcut: "Ctrl+Shift+Z" },
        { label: "View: Zoom In",                shortcut: "+" },
        { label: "View: Fit to View",            shortcut: "Shift+/" },
        { label: "View: GPU Diagnostics",        shortcut: "" },
        { label: "Composition: New Composition", shortcut: "" },
        { label: "Layer: New Solid",             shortcut: "" },
        { label: "Layer: New Text",              shortcut: "" },
        { label: "Layer: Add to Render Queue",   shortcut: "Ctrl+M" },
        { label: "Help: About Nova Compositor",  shortcut: "" },
    ]

    property string filterText: ""

    property var filteredCommands: {
        if (filterText.length === 0) return allCommands
        var q = filterText.toLowerCase()
        return allCommands.filter(function(c) { return c.label.toLowerCase().indexOf(q) >= 0 })
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Search input
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "transparent"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text { text: "⌕"; color: "#8888a0"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }

                // Search field with placeholder text overlay
                Item {
                    width: parent.width - 40
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        text: ""
                        color: "#e8e8ea"
                        font.pixelSize: 15
                        font.family: "Inter"
                        clip: true

                        Component.onCompleted: forceActiveFocus()
                        onTextChanged: root.filterText = text
                        Keys.onEscapePressed: root.visible = false
                    }

                    // Placeholder overlay
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Type a command…"
                        color: "#4a4a60"
                        font.pixelSize: 15
                        font.family: "Inter"
                        visible: searchInput.text.length === 0
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

        // Results list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.filteredCommands

            delegate: Rectangle {
                width: ListView.view.width
                height: 38
                color: ListView.isCurrentItem ? "#1e4a80" : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 0

                    Text {
                        text: modelData.label
                        color: "#dcdce8"
                        font.pixelSize: 13
                        font.family: "Inter"
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - shortcutText.width
                    }

                    Text {
                        id: shortcutText
                        text: modelData.shortcut
                        color: "#5a5a72"
                        font.pixelSize: 11
                        font.family: "Inter"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.ListView.view.currentIndex = index
                    onClicked: {
                        root.visible = false
                        // TODO: dispatch command
                    }
                }
            }
        }

        // Footer
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#13131c"
            radius: 0

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2a2a38"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                spacing: 16

                Text { text: "↵ to run  ·  Esc to close"; color: "#3a3a52"; font.pixelSize: 10; font.family: "Inter"; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
