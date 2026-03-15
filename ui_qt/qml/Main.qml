import QtQuick
import QtQuick.Controls.Basic
import NovaCompositor

Window {
    id: root
    width: 1600
    height: 900
    minimumWidth: 1024
    minimumHeight: 600
    visible: true
    title: "Nova Compositor"
    color: "#0f0f14"

    // ── Splash screen (shown for 2.5s on startup) ────────────────────────────
    SplashScreen {
        id: splash
        anchors.centerIn: parent
        z: 1000
        visible: true

        onDismissed: {
            splash.visible = false
        }
    }

    // ── Main app (shown after splash) ─────────────────────────────────────────
    NovaApp {
        anchors.fill: parent
        visible: !splash.visible
        opacity: splash.visible ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
}
