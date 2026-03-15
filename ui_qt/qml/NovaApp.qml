import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import NovaCompositor
import "components"
import "panels"
import "rooms"

/// Main application layout: menu bar + workspace + status bar.
Item {
    id: root

    // ── Nova palette ──────────────────────────────────────────────────────────
    readonly property color bg0:       "#0f0f14"
    readonly property color bg1:       "#161620"
    readonly property color bg2:       "#1e1e28"
    readonly property color border:    "#2a2a38"
    readonly property color textPri:   "#e8e8ea"
    readonly property color textSec:   "#8888a0"
    readonly property color accent:    "#4a9eff"

    function openExportDialog() { exportDialog.open() }

    Rectangle {
        anchors.fill: parent
        color: root.bg0

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Menu Bar ──────────────────────────────────────────────────────
            MenuBar {
                Layout.fillWidth: true
            }

            // ── Toolbar ───────────────────────────────────────────────────────
            ToolbarPanel {
                Layout.fillWidth: true
            }

            // ── Workspace switcher ─────────────────────────────────────────────
            WorkspaceSwitcher {
                id: workspaceSwitcher
                Layout.fillWidth: true
            }

            // ── Main panel area (Rooms) ────────────────────────────────────────
            StackLayout {
                id: roomStack
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Map workspace names to their corresponding Room indices
                currentIndex: {
                    switch (workspaceSwitcher.activeWorkspace) {
                        case "Edit": return 0;
                        case "Compositing": return 1;
                        case "Node Graph": return 2;
                        case "Color": return 3;
                        case "Keying": return 4;
                        case "3D Scene": return 5;
                        case "Tracking": return 6;
                        case "Rigging": return 7;
                        case "AI Video": return 8;
                        case "Particles": return 9;
                        case "Motion Packs": return 10;
                        default: return 1; // Default to Compositing
                    }
                }

                EditRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                CompositingRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                NodeGraphRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                ColorGradingRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                KeyingRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                Scene3DRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                TrackingRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                RiggingRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                AIVideoRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                ParticlesRoom { Layout.fillWidth: true; Layout.fillHeight: true }
                MotionPacksRoom { Layout.fillWidth: true; Layout.fillHeight: true }
            }

            // ── Status Bar ────────────────────────────────────────────────────
            NovaStatusBar {
                Layout.fillWidth: true
            }
        }
    }

    ExportDialog {
        id: exportDialog
    }

    // ── Command Palette (Ctrl+Shift+P) ─────────────────────────────────────────
    CommandPalette {
        id: commandPalette
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 60
        visible: false
        z: 999
    }

    Shortcut {
        sequence: "Ctrl+Shift+P"
        onActivated: commandPalette.visible = !commandPalette.visible
    }
}
