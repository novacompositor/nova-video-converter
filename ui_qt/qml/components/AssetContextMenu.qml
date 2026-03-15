import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Reusable dark‑themed context menu for media assets.
/// Usage:
///   AssetContextMenu {
///       id: ctxMenu
///       onOpenInViewer:        { ... }
///       onCreateComp:          { ... }
///       onShowProperties:      { ... }
///       onRemoveFromProject:   { ... }
///   }
///   // trigger:
///   ctxMenu.showAt(mouseX, mouseY, assetId, assetName, assetPath, assetKind)
Popup {
    id: root

    // ── Signals ──────────────────────────────────────────
    signal openInViewer()
    signal createComp()
    signal showProperties()
    signal removeFromProject()

    // ── Active asset data ─────────────────────────────────
    property string assetId:   ""
    property string assetName: ""
    property string assetPath: ""
    property string assetKind: ""

    /// Call this to open the menu at the right position
    function showAt(mx, my, id, name, path, kind) {
        assetId   = id;
        assetName = name;
        assetPath = path;
        assetKind = kind;
        x = mx;
        y = my;
        open();
    }

    // ── Popup settings ────────────────────────────────────
    width:        242
    padding:      5
    closePolicy:  Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color:        "#1c1c2a"
        border.color: "#3d3d56"
        border.width: 1
        radius:       7

        // Subtle inner shadow ring
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
        property bool   danger:    false
        signal activated()

        width:  232
        height: 34
        radius: 5
        color:  ma.containsMouse
                    ? (danger ? "#321818" : "#252540")
                    : "transparent"

        Row {
            anchors.fill:       parent
            anchors.leftMargin: 12
            spacing:            10

            Text {
                text:                  icon
                color:                 danger ? "#ff6060" : iconColor
                font.pixelSize:        14
                anchors.verticalCenter: parent.verticalCenter
                width:                 18
                horizontalAlignment:    Text.AlignHCenter
            }

            Text {
                text:                   label
                color:                  danger ? "#ff7070" : "#d4d4ec"
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
        width:  222
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
            label:     "Open in Viewer"
            icon:      "▶"
            iconColor: "#4a9eff"
            onActivated: root.openInViewer()
        }

        Divider {}

        MenuRow {
            label:     "New Composition from Clip"
            icon:      "⊞"
            iconColor: "#4adf9e"
            onActivated: root.createComp()
        }

        Divider {}

        MenuRow {
            label:     "Clip Interpretation..."
            icon:      "⚙"
            iconColor: "#aaaacc"
            onActivated: root.showProperties()
        }

        Divider {}

        MenuRow {
            label:  "Remove from Project"
            icon:   "✕"
            danger: true
            onActivated: root.removeFromProject()
        }
    }
}
