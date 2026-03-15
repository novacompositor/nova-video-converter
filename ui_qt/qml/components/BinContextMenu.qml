import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Reusable dark‑themed context menu for the empty space of the Media Bin.
/// Usage:
///   BinContextMenu {
///       id: binContextMenu
///       onImportMedia: { ... }
///       onImportXml:   { ... }
///       onNewSequence: { ... }
///   }
///   // trigger:
///   binContextMenu.showAt(mouseX, mouseY)
Popup {
    id: root

    // ── Signals ──────────────────────────────────────────
    signal importMedia()
    signal importXml()
    signal newSequence()

    function showAt(mx, my) {
        x = mx;
        y = my;
        open();
    }

    // ── Popup settings ────────────────────────────────────
    width:        220
    padding:      5
    closePolicy:  Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color:        "#1c1c2a"
        border.color: "#3d3d56"
        border.width: 1
        radius:       7

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 1
            color:           "transparent"
            border.color:    "#ffffff"
            border.width:    0
            radius:          7
            opacity:         0.04
        }
    }

    // ── Row template ─────────────────────────────────────
    component MenuRow: Rectangle {
        property string label:     ""
        property string icon:      ""
        property color  iconColor: "#8888aa"
        signal activated()

        width:  210
        height: 34
        radius: 5
        color:  ma.containsMouse ? "#252540" : "transparent"

        Row {
            anchors.fill:       parent
            anchors.leftMargin: 12
            spacing:            10

            Text {
                text:                  icon
                color:                 iconColor
                font.pixelSize:        14
                anchors.verticalCenter: parent.verticalCenter
                width:                 18
                horizontalAlignment:    Text.AlignHCenter
            }

            Text {
                text:                   label
                color:                  "#d4d4ec"
                font.pixelSize:         13
                font.family:            "Inter"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: ma
            anchors.fill:  parent
            hoverEnabled:  true
            cursorShape:   Qt.PointingHandCursor
            onClicked: { root.close(); activated(); }
        }
    }

    // ── Divider template ─────────────────────────────────
    component Divider: Rectangle {
        width:  200
        height: 1
        color:  "#2d2d45"
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    }

    // ── Content ───────────────────────────────────────────
    contentItem: Column {
        spacing: 1
        topPadding: 2
        bottomPadding: 2

        MenuRow {
            label:     "Import Media..."
            icon:      "📥"
            iconColor: "#4a9eff"
            onActivated: root.importMedia()
        }

        Divider {}

        MenuRow {
            label:     "Import XML..."
            icon:      "📄"
            iconColor: "#aaaacc"
            onActivated: root.importXml()
        }

        Divider {}

        MenuRow {
            label:     "New Sequence..."
            icon:      "🎬"
            iconColor: "#4adf9e"
            onActivated: root.newSequence()
        }
    }
}
