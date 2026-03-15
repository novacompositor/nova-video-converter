import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: "#161620"

        Text {
            anchors.centerIn: parent
            text: "Keying Room (Spectrum Keyer)"
            color: "#8888a0"
            font.pixelSize: 24
            font.family: "Inter"
        }
    }
}
