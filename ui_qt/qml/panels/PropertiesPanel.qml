import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import NovaCompositor

/// Properties panel matches After Effects right-side info and effects & presets
Rectangle {
    color: "#161620"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Tabs mock
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#2d333b"
            border.color: "#16191d"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#374151"
                    Text { anchors.centerIn: parent; text: "Properties"; color: "#ffffff"; font.pixelSize: 11; font.family: "Inter" }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: "#3b82f6" }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    Text { anchors.centerIn: parent; text: "Libraries"; color: "#9ca3af"; font.pixelSize: 11; font.family: "Inter" }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    Text { anchors.centerIn: parent; text: "Info"; color: "#9ca3af"; font.pixelSize: 11; font.family: "Inter" }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 12
                
                Item { height: 4 }
                
                // Align & Distribute
                Rectangle {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    height: 80
                    color: "#23272e"
                    border.color: "#374151"
                    radius: 4
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            color: "#2d333b"
                            radius: 4
                            Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "ALIGN & DISTRIBUTE"; color: "#9ca3af"; font.pixelSize: 10; font.bold: true; font.family: "Inter" }
                        }
                        
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 8
                            spacing: 4
                            Repeater {
                                model: 6
                                Rectangle { width: 24; height: 24; color: "#1a1e23"; border.color: "#374151"; radius: 2 }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
                
                // Character
                Rectangle {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    height: 160
                    color: "#23272e"
                    border.color: "#374151"
                    radius: 4
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            color: "#2d333b"
                            radius: 4
                            Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "CHARACTER"; color: "#9ca3af"; font.pixelSize: 10; font.bold: true; font.family: "Inter" }
                        }
                        
                        Item { Layout.fillWidth: true; Layout.fillHeight: true } // Placeholder for fonts
                    }
                }
                
                // Effects & Presets
                Rectangle {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    height: 280
                    color: "#23272e"
                    border.color: "#374151"
                    radius: 4
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            color: "#2d333b"
                            radius: 4
                            Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "EFFECTS & PRESETS"; color: "#9ca3af"; font.pixelSize: 10; font.bold: true; font.family: "Inter" }
                        }
                        
                        // Search bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.margins: 8
                            height: 24
                            color: "#1a1e23"
                            border.color: "#374151"
                            radius: 2
                            Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; text: "Search Effects..."; color: "#6b7280"; font.pixelSize: 11; font.family: "Inter" }
                        }
                        
                        Item { Layout.fillWidth: true; Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
