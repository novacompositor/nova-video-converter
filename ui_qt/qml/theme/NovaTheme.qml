import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

/// Nova dark color palette — single source of truth for all UI colors.
pragma Singleton
QtObject {
    // Surfaces
    readonly property color bg0:     "#0f0f14"   // Deepest background
    readonly property color bg1:     "#161620"   // Panel background
    readonly property color bg2:     "#1e1e28"   // Panel card / hover
    readonly property color bg3:     "#252530"   // Input / separator
    readonly property color border:  "#2a2a38"   // Border / divider

    // Text
    readonly property color textPrimary:   "#e8e8ea"
    readonly property color textSecondary: "#8888a0"
    readonly property color textDisabled:  "#4a4a60"
    readonly property color textAccent:    "#4a9eff"

    // Accent
    readonly property color accentBlue:    "#4a9eff"
    readonly property color accentBlueDim: "#1e4a80"
    readonly property color accentGreen:   "#3acc88"
    readonly property color accentYellow:  "#f0c040"
    readonly property color accentRed:     "#e05050"

    // Panel header
    readonly property color headerBg:  "#13131c"
    readonly property color headerText: "#9090aa"

    // Selection
    readonly property color selectionBg: "#1e4a80"
    readonly property color selectionBorder: "#4a9eff"

    // Font family
    readonly property string fontFamily: "Inter"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeBase: 13
    readonly property int fontSizeMedium: 15
    readonly property int fontSizeLarge: 18
}
