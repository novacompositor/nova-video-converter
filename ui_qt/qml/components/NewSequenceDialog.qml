import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Controls
import QtQuick.Layouts

/// Dialog for creating a new Sequence (Timeline)
/// Usage:
///   NewSequenceDialog {
///       id: seqDialog
///       onAccepted: (name, width, height, fpsNum, fpsDen) => { ... }
///   }
Popup {
    id: root

    // ── Signals ──────────────────────────────────────────
    signal accepted(string name, int width, int height, int fpsNum, int fpsDen, int sampleRate)

    // ── Popup settings ────────────────────────────────────
    width:        380
    height:       360
    padding:      0
    modal:        true
    focus:        true
    closePolicy:  Popup.CloseOnEscape
    parent:       Overlay.overlay
    x:            Math.round((parent.width - width) / 2)
    y:            Math.round((parent.height - height) / 2)

    background: Rectangle {
        color:        "#181824"
        border.color: "#3a3a50"
        border.width: 1
        radius:       8
    }

    // ── Custom Controls ───────────────────────────────────
    component StyledLabel: Text {
        color:       "#8888a0"
        font.pixelSize: 11
        font.family: "Inter"
        font.weight: Font.DemiBold
    }

    component StyledTextField: TextField {
        color: "#ffffff"
        font.pixelSize: 13
        font.family: "Inter"
        background: Rectangle {
            color:        "#12121a"
            border.color: parent.activeFocus ? "#4a9eff" : "#2a2a35"
            border.width: 1
            radius:       4
        }
    }

    component StyledComboBox: ComboBox {
        id: cb
        font.pixelSize: 13
        font.family: "Inter"
        background: Rectangle {
            color:        "#12121a"
            border.color: cb.activeFocus ? "#4a9eff" : "#2a2a35"
            border.width: 1
            radius:       4
        }
        contentItem: Text {
            text:  cb.currentText
            color: "#ffffff"
            font:  cb.font
            verticalAlignment: Text.AlignVCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
        }
        popup: Popup {
            y: cb.height - 1
            width: cb.width
            padding: 1
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: cb.popup.visible ? cb.delegateModel : null
                currentIndex: cb.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator { }
            }
            background: Rectangle {
                color: "#1c1c2a"
                border.color: "#3a3a50"
                border.width: 1
                radius: 4
            }
        }
        delegate: ItemDelegate {
            width: cb.width
            height: 32
            contentItem: Text {
                text: modelData
                color: highlighted ? "#ffffff" : "#d0d0e0"
                font: cb.font
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: highlighted ? "#4a9eff" : "transparent"
                radius: 2
            }
        }
    }

    // ── Content ───────────────────────────────────────────
    contentItem: ColumnLayout {
        spacing: 0
        anchors.fill: parent

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#222232"
            radius: 8
            Rectangle {
                width: parent.width
                height: 8
                color: parent.color
                anchors.bottom: parent.bottom
            }
            Rectangle {
                width: parent.width
                height: 1
                color: "#3a3a50"
                anchors.bottom: parent.bottom
            }

            Text {
                text: "New Sequence"
                color: "#ffffff"
                font.pixelSize: 14
                font.family: "Inter"
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
            }

            // Allow dragging the dialog
            MouseArea {
                anchors.fill: parent
                // Exclude close button area visually (close button handles its own clicks over this)
                property real lastX: 0
                property real lastY: 0
                onPressed: (mouse) => {
                    lastX = mouse.x
                    lastY = mouse.y
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        root.x += mouse.x - lastX
                        root.y += mouse.y - lastY
                    }
                }
            }

            Text {
                text: "✕"
                color: "#8888a0"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 16
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        // Form
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                anchors.fill: parent
                anchors.margins: 24
                columns: 2
                rowSpacing: 16
                columnSpacing: 16

                StyledLabel { text: "Sequence Name" }
                StyledTextField {
                    id: nameField
                    Layout.fillWidth: true
                    text: "Sequence 01"
                }

                StyledLabel { text: "Resolution" }
                StyledComboBox {
                    id: resBox
                    Layout.fillWidth: true
                    model: [
                        "1920 x 1080 (HD)",
                        "3840 x 2160 (4K UHD)",
                        "1080 x 1920 (Vertical HD)",
                        "1280 x 720 (HD Ready)",
                        "1080 x 1080 (Square)"
                    ]
                }

                StyledLabel { text: "Frame Rate" }
                StyledComboBox {
                    id: fpsBox
                    Layout.fillWidth: true
                    model: ["23.976 fps", "24 fps", "25 fps", "29.97 fps", "30 fps", "50 fps", "59.94 fps", "60 fps"]
                    currentIndex: 4 // default 30 fps
                }

                StyledLabel { text: "Audio Sample Rate" }
                StyledComboBox {
                    id: audioBox
                    Layout.fillWidth: true
                    model: ["48000 Hz", "44100 Hz"]
                    currentIndex: 0
                }
                
                Item { Layout.fillHeight: true } // Spacer
            }
        }

        // Footer / Buttons
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "#181824"
            
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2a2a35"
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Cancel
                Rectangle {
                    width: 80; height: 32; radius: 4
                    color: cancelMa.containsMouse ? "#2a2a35" : "transparent"
                    border.color: "#3a3a50"
                    Text { text: "Cancel"; color: "#d0d0e0"; font.pixelSize: 13; font.family: "Inter"; anchors.centerIn: parent }
                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                // Create
                Rectangle {
                    width: 100; height: 32; radius: 4
                    color: createMa.containsMouse ? "#5ba7ff" : "#4a9eff"
                    Text { text: "Create"; color: "#ffffff"; font.pixelSize: 13; font.family: "Inter"; font.weight: Font.DemiBold; anchors.centerIn: parent }
                    MouseArea {
                        id: createMa
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // parse resolution
                            let parts = resBox.currentText.split(" ");
                            let w = parseInt(parts[0]);
                            let h = parseInt(parts[2]);
                            
                            // parse fps
                            let fpsStr = fpsBox.currentText;
                            let fNum = 30000;
                            let fDen = 1001;
                            if (fpsStr.includes("23.976")) { fNum = 24000; fDen = 1001; }
                            else if (fpsStr.includes("24")) { fNum = 24; fDen = 1; }
                            else if (fpsStr.includes("25")) { fNum = 25; fDen = 1; }
                            else if (fpsStr.includes("29.97")) { fNum = 30000; fDen = 1001; }
                            else if (fpsStr.includes("30")) { fNum = 30; fDen = 1; }
                            else if (fpsStr.includes("50")) { fNum = 50; fDen = 1; }
                            else if (fpsStr.includes("59.94")) { fNum = 60000; fDen = 1001; }
                            else if (fpsStr.includes("60")) { fNum = 60; fDen = 1; }

                            // sample rate
                            let sr = audioBox.currentIndex === 0 ? 48000 : 44100;

                            root.accepted(nameField.text, w, h, fNum, fDen, sr);
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
