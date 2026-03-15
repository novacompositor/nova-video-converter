import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import NovaCompositor

/// Graph Editor panel — keyframe curve editor.
Rectangle {
    color: "#0f0f14"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader { title: "Graph Editor" }

        // Empty curve canvas
        Canvas {
            Layout.fillWidth: true
            Layout.fillHeight: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = "#0f0f14"
                ctx.fillRect(0, 0, width, height)

                // Horizontal grid lines
                ctx.strokeStyle = "#1e1e28"
                ctx.lineWidth = 1
                var step = 30
                for (var y = step; y < height; y += step) {
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }

                // Placeholder label
                ctx.fillStyle = "#3a3a50"
                ctx.font = "12px Inter, sans-serif"
                ctx.textAlign = "center"
                ctx.fillText("No animation data", width / 2, height / 2)
            }
        }
    }
}
