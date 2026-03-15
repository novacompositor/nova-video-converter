import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Splash screen displayed on startup.
/// Auto-dismisses after splashDuration ms, or on tap.
Item {
    id: root
    width: 700
    height: 420

    signal dismissed()

    readonly property int splashDuration: 2500

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#0f0f14"
        radius: 6
        border.color: "#2a2a38"
        border.width: 1


        // Splash image
        Image {
            id: splashImg
            anchors.fill: parent
            source: "file:///home/art/NovaCompositor/ui_qt/resources/splash/splash.png"
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: false

            opacity: 0
            NumberAnimation on opacity {
                from: 0; to: 1
                duration: 600
                easing.type: Easing.OutCubic
                running: true
            }
        }

        // Version badge
        Text {
            id: versionText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: copyrightText.top
            anchors.bottomMargin: 8
            text: "Version " + APP_VERSION + " — Phase 1 Build"
            color: "#5a5a72"
            font.pixelSize: 13
            font.family: "Inter"
        }

        // Progress bar
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.left: parent.left
            height: 2
            color: "#4a9eff"
            radius: 1
            width: 0

            NumberAnimation on width {
                from: 0
                to: root.width
                duration: root.splashDuration - 200
                easing.type: Easing.Linear
                running: true
            }
        }

        // Copyright
        Text {
            id: copyrightText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: progressBar.top
            anchors.bottomMargin: 12
            text: "© 2026 Nova Compositor Team — Open Source"
            color: "#3a3a52"
            font.pixelSize: 11
            font.family: "Inter"
        }
    }

    // Auto-dismiss timer
    Timer {
        interval: root.splashDuration
        running: true
        onTriggered: root.dismissed()
    }

    // Click to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }
}
