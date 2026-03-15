import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs // For FileDialog
import "../components"

/// Project & Media Bin panel (left column).
Rectangle {
    id: root
    color: "#161620"

    signal assetDoubleClicked(string path)

    readonly property color borderColor: "#2a2a38"
    readonly property color textSec: "#8888a0"
    readonly property color textPri: "#e8e8ea"
    readonly property color accent: "#4a9eff"

    Component.onCompleted: {
        // Initialization if needed
    }

    // --- Track asset_id for context menu actions ---
    property string selectedAssetId: ""
    property string selectedAssetName: ""
    property string selectedAssetPath: ""
    property string selectedAssetKind: ""
    property string selectedAssetFps: ""
    property string selectedAssetRes: ""

    // --- Listen for imported events ---
    Connections {
        target: appBridge
        function onEngineEventReceived(eventJson) {
            try {
                let response = JSON.parse(eventJson);
                if (response && response.events && Array.isArray(response.events)) {
                    for (let ev of response.events) {
                        if (ev.type === "AssetImported" && ev.payload) {
                            console.log("QML ProjectPanel: Asset imported: " + ev.payload.name);
                        } else if (ev.type === "ProjectChanged") {
                            appBridge.dispatchCommand(JSON.stringify({ type: "SyncState" }));
                        } else if (ev.type === "StateSynced" && ev.payload && ev.payload.project) {
                            let proj = ev.payload.project;
                            assetModel.clear();
                            // Add Sequences
                            if (proj.sequences && Array.isArray(proj.sequences)) {
                                for (let seq of proj.sequences) {
                                    assetModel.append({
                                        name: seq.name,
                                        isFolder: false,
                                        kind: "Sequence",
                                        path: "",
                                        asset_id: seq.id
                                    });
                                }
                            }
                            // Add Assets
                            if (proj.assets && Array.isArray(proj.assets)) {
                                for (let asset of proj.assets) {
                                    assetModel.append({
                                        name: asset.name,
                                        isFolder: false,
                                        kind: asset.kind || "Data",
                                        path: asset.path,
                                        asset_id: asset.asset_id || asset.id || ""
                                    });
                                }
                            }
                        }
                    }
                }
            } catch (e) {
                console.error("Failed to parse event JSON:", e);
            }
        }
    }

    // ─────── Context Menu ───────
    // ─────── Dark Context Menu ───────
    Popup {
        id: assetContextMenu
        width: 242
        padding: 5
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string assetId:   ""
        property string assetName: ""
        property string assetPath: ""
        property string assetKind: ""

        function showAt(mx, my, id, name, path, kind) {
            assetId = id; assetName = name; assetPath = path; assetKind = kind;
            x = mx; y = my; open();
        }

        background: Rectangle {
            color: "#1c1c2a"; border.color: "#3d3d56"; border.width: 1; radius: 7
        }

        contentItem: Column {
            spacing: 1; topPadding: 4; bottomPadding: 4

            component MRow: Rectangle {
                property string label: ""
                property string icon:  ""
                property color  clr:   "#8888aa"
                property bool   danger: false
                signal act()
                width: 232; height: 34; radius: 5
                color: mra.containsMouse ? (danger ? "#321818" : "#252540") : "transparent"
                Row { anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                    Text { text: icon; color: danger ? "#ff6060" : clr; font.pixelSize: 14; width: 18; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { text: label; color: danger ? "#ff7070" : "#d4d4ec"; font.pixelSize: 13; font.family: "Inter"; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: mra; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { assetContextMenu.close(); act(); } }
            }

            MRow { label: "Open in Viewer"; icon: "▶"; clr: "#4a9eff"
                onAct: root.assetDoubleClicked(assetContextMenu.assetPath) }

            Rectangle { width: 222; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter }

            MRow { label: "New Composition from Clip"; icon: "⊞"; clr: "#4adf9e"
                visible: assetContextMenu.assetKind !== "Sequence"
                onAct: {
                    if (assetContextMenu.assetId !== "")
                        appBridge.dispatchCommand(JSON.stringify({ type: "CreateCompFromAsset", payload: { asset_id: assetContextMenu.assetId } }));
                } }

            Rectangle { width: 222; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter; visible: assetContextMenu.assetKind !== "Sequence" }

            MRow { label: "Clip Interpretation..."; icon: "⚙"; clr: "#aaaacc"
                visible: assetContextMenu.assetKind !== "Sequence"
                onAct: propertiesPopup.open() }

            MRow { label: "Sequence Settings..."; icon: "⚙"; clr: "#aaaacc"
                visible: assetContextMenu.assetKind === "Sequence"
                onAct: console.log("Sequence settings for", assetContextMenu.assetName) }

            Rectangle { width: 222; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter }

            MRow { label: "Remove from Project"; icon: "✕"; danger: true
                onAct: {
                    if (assetContextMenu.assetId !== "") {
                        appBridge.dispatchCommand(JSON.stringify({ type: "RemoveAsset", payload: { asset_id: assetContextMenu.assetId } }));
                        for (let i = 0; i < assetModel.count; i++) {
                            if (assetModel.get(i).asset_id === assetContextMenu.assetId) { assetModel.remove(i); break; }
                        }
                    }
                } }
        }
    }

    // ─────── Properties Popup ───────
    Popup {
        id: propertiesPopup
        width: 440
        height: 340
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        background: Rectangle {
            color: "#181824"
            border.color: "#3a3a54"
            border.width: 1
            radius: 8
        }

        contentItem: ColumnLayout {
            spacing: 0

            // Title bar
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#1f1f30"
                radius: 8

                // Flatten bottom corners
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 8
                    color: parent.color
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    spacing: 8
                    Text { text: "⚙"; color: "#8888a0"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "Clip Interpretation — " + root.selectedAssetName
                        color: "#d0d0e8"
                        font.pixelSize: 13
                        font.family: "Inter"
                        font.bold: true
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "×"
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeBtnMa.containsMouse ? "#ff6666" : "#666688"
                    font.pixelSize: 18
                    MouseArea { id: closeBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: propertiesPopup.close() }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2a3e" }

            Item { height: 16 }

            // Grid
            GridLayout {
                columns: 2
                columnSpacing: 20
                rowSpacing: 12
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                Text { text: "File:";       color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
                Text { text: root.selectedAssetPath; color: "#c0c0d8"; font.pixelSize: 11; font.family: "Inter"; elide: Text.ElideLeft; Layout.fillWidth: true }

                Text { text: "Type:";       color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
                Rectangle {
                    width: kindBadgeTxt.implicitWidth + 14; height: 20; radius: 10
                    color: root.selectedAssetKind === "Video" ? "#1a3a5a" :
                           root.selectedAssetKind === "Audio" ? "#1a4a3a" : "#4a3a1a"
                    Text {
                        id: kindBadgeTxt
                        anchors.centerIn: parent
                        text: root.selectedAssetKind
                        color: root.selectedAssetKind === "Video" ? "#4a9eff" :
                               root.selectedAssetKind === "Audio" ? "#4adf9e" : "#e09e4a"
                        font.pixelSize: 11
                        font.family: "Inter"
                        font.bold: true
                    }
                }

                Text { text: "Frame Rate:"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
                RowLayout {
                    spacing: 8
                    ComboBox {
                        id: fpsCombo
                        model: ["23.976", "24", "25", "29.97", "30", "50", "59.94", "60"]
                        currentIndex: 4
                        implicitWidth: 120
                        background: Rectangle { color: "#252535"; radius: 4; border.color: "#3a3a50"; border.width: 1 }
                        contentItem: Text { leftPadding: 10; text: fpsCombo.displayText; color: "#d0d0e8"; font.pixelSize: 12; font.family: "Inter"; verticalAlignment: Text.AlignVCenter }
                        popup: Popup {
                            y: fpsCombo.height
                            width: fpsCombo.width
                            padding: 4
                            background: Rectangle { color: "#1c1c2a"; border.color: "#3a3a50"; border.width: 1; radius: 4 }
                            contentItem: ListView {
                                model: fpsCombo.delegateModel
                                implicitHeight: contentHeight
                                clip: true
                            }
                        }
                    }
                    Text { text: "fps"; color: "#8888a0"; font.pixelSize: 12 }
                }

                Text { text: "Fields:"; color: "#8888a0"; font.pixelSize: 12; font.family: "Inter" }
                ComboBox {
                    id: fieldsCombo
                    model: ["Progressive", "Upper Field First", "Lower Field First"]
                    implicitWidth: 200
                    background: Rectangle { color: "#252535"; radius: 4; border.color: "#3a3a50"; border.width: 1 }
                    contentItem: Text { leftPadding: 10; text: fieldsCombo.displayText; color: "#d0d0e8"; font.pixelSize: 12; font.family: "Inter"; verticalAlignment: Text.AlignVCenter }
                    popup: Popup {
                        y: fieldsCombo.height
                        width: fieldsCombo.width
                        padding: 4
                        background: Rectangle { color: "#1c1c2a"; border.color: "#3a3a50"; border.width: 1; radius: 4 }
                        contentItem: ListView {
                            model: fieldsCombo.delegateModel
                            implicitHeight: contentHeight
                            clip: true
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Bottom divider + buttons
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2a3e" }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 12
                spacing: 10

                // Cancel button
                Rectangle {
                    implicitWidth: 90; implicitHeight: 30; radius: 5
                    color: cancelMa.containsMouse ? "#252535" : "#1c1c2a"
                    border.color: "#3a3a50"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#c0c0d8"; font.pixelSize: 12; font.family: "Inter" }
                    MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: propertiesPopup.close() }
                }

                // Apply button
                Rectangle {
                    implicitWidth: 90; implicitHeight: 30; radius: 5
                    color: applyMa.containsMouse ? "#5ab0ff" : "#4a9eff"
                    Text { anchors.centerIn: parent; text: "Apply"; color: "#ffffff"; font.pixelSize: 12; font.family: "Inter"; font.bold: true }
                    MouseArea {
                        id: applyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let fps = fpsCombo.currentText;
                            let [num, den] = fps === "23.976" ? [24000, 1001] :
                                             fps === "29.97"  ? [30000, 1001] :
                                             fps === "59.94"  ? [60000, 1001] :
                                             [parseInt(fps) * 1000, 1000];
                            appBridge.dispatchCommand(JSON.stringify({
                                type: "UpdateAssetProperties",
                                payload: { asset_id: root.selectedAssetId, frame_rate: { num: num, den: den } }
                            }));
                            propertiesPopup.close();
                        }
                    }
                }
            }
        }
    }


    // ─────── File Import Dialog ───────
    FileDialog {
        id: importDialog
        title: "Import Media"
        nameFilters: [
            "All Supported Media (*.png *.jpg *.jpeg *.webp *.svg *.psd *.mov *.mp4 *.wav *.m4a)",
            "Image Files (*.png *.jpg *.jpeg *.webp *.svg *.psd)",
            "Audio/Video Files (*.mov *.mp4 *.wav *.m4a)",
            "All files (*)"
        ]
        onAccepted: {
            let path = selectedFile.toString().replace("file://", "");
            let cmd = {
                type: "ImportAsset",
                payload: { path: path, add_to_composition: null }
            };
            let res = appBridge.dispatchCommand(JSON.stringify(cmd)); console.log("CreateSequence result: " + res);
        }
    }

    FileDialog {
        id: xmlFileDialog
        title: "Import FCPXML Sequence"
        nameFilters: ["FCPXML files (*.fcpxml)", "All files (*)"]
        onAccepted: {
            let path = selectedFile.toString().replace("file://", "");
            let cmd = { type: "OpenProject", payload: { path: path } };
            let res = appBridge.dispatchCommand(JSON.stringify(cmd)); console.log("CreateSequence result: " + res);
        }
    }

    // ── Dark context menu for empty bin space ──
    Popup {
        id: binContextMenu
        width: 200
        padding: 5
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        function showAt(mx, my) { x = mx; y = my; open(); }

        background: Rectangle {
            color: "#1c1c2a"; border.color: "#3d3d56"; border.width: 1; radius: 7
        }

        contentItem: Column {
            spacing: 1; topPadding: 4; bottomPadding: 4

                        component BinRow: Rectangle {
                            property string label: ""
                            property string icon: ""
                            property color clr: "#8888aa"
                            signal act()
                            width: 190; height: 34; radius: 5
                            color: mraBin.containsMouse ? "#252540" : "transparent"
                            Row { anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                Text { text: icon; color: clr; font.pixelSize: 14; width: 18; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter }
                                Text { text: label; color: "#d4d4ec"; font.pixelSize: 13; font.family: "Inter"; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: mraBin; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { binContextMenu.close(); act(); } }
                        }

                        BinRow { label: "Import Media..."; icon: "📥"; clr: "#4a9eff"
                            onAct: importDialog.open() }
                        Rectangle { width: 180; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter }
                        
                        BinRow { label: "Import XML..."; icon: "📄"; clr: "#aaaacc"
                            onAct: xmlFileDialog.open() }
                        Rectangle { width: 180; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter }
                        
                        BinRow { label: "New Sequence..."; icon: "🎬"; clr: "#4adf9e"
                            onAct: newSeqDialog.open() }
        }
    }

    NewSequenceDialog {
        id: newSeqDialog
        onAccepted: (name, w, h, fpsNum, fpsDen, sr) => {
            let cmd = {
                type: "CreateSequence",
                payload: {
                    name: name,
                    resolution: { width: w, height: h },
                    frame_rate: { num: fpsNum, den: fpsDen }
                }
            };
            let rs = appBridge.dispatchCommand(JSON.stringify(cmd));
            console.log("CREATE_SEQUENCE_RESULT: " + rs);
            console.log("CREATE_SEQUENCE_RESULT: " + rs);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Panel tabs
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "#13131c"

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: ["PROJECT", "EFFECTS"]
                    delegate: Rectangle {
                        property bool isActive: index === 0
                        Layout.fillHeight: true
                        Layout.preferredWidth: 90
                        color: isActive ? "#161620" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: isActive ? root.accent : root.textSec
                            font.pixelSize: 10
                            font.family: "Inter"
                            font.letterSpacing: 1.0
                        }

                        Rectangle {
                            visible: isActive
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 2
                            color: root.accent
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: root.borderColor
            }
        }

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "#0f0f14"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 6

                Text { text: "⌕"; color: root.textSec; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Search assets…"; color: root.textSec; font.pixelSize: 12; font.family: "Inter"; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: root.borderColor
            }
        }

        // ─── Asset List ───
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            id: assetListView

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: (eventPoint) => {
                    binContextMenu.showAt(eventPoint.position.x, eventPoint.position.y);
                }
            }

            model: ListModel {
                id: assetModel
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                text: "No media imported.\nRight-click to import media or XML."
                color: root.textSec
                font.pixelSize: 12
                font.family: "Inter"
                horizontalAlignment: Text.AlignHCenter
                visible: assetModel.count === 0
            }

            delegate: Item {
                id: delegateRoot
                width: ListView.view.width
                height: 36

                Rectangle {
                    id: delegateRect
                    anchors.fill: parent
                    color: hoverHandler.hovered ? "#252535" : (index % 2 === 0 ? "transparent" : "#1c1c28")

                    // ── Drag support ─────────────────────────
                    Drag.active: dragHandler.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.mimeData: ({
                        "application/x-nova-asset-id": model.asset_id,
                        "text/plain": model.name
                    })

                    // DragHandler handles only left-button drag.
                    // Because we use no MouseArea here, nothing steals the press.
                    DragHandler {
                        id: dragHandler
                        acceptedButtons: Qt.LeftButton
                        grabPermissions: PointerHandler.CanTakeOverFromAnything
                    }

                    // Hover tracking (no button involvement – safe to coexist)
                    HoverHandler {
                        id: hoverHandler
                    }

                    // Double-click with left button → open asset
                    TapHandler {
                        id: doubleTapHandler
                        acceptedButtons: Qt.LeftButton
                        gesturePolicy: TapHandler.WithinBounds
                        onDoubleTapped: root.assetDoubleClicked(model.path)
                    }

                    // Single right-click → context menu
                    TapHandler {
                        id: rightClickHandler
                        acceptedButtons: Qt.RightButton
                        gesturePolicy: TapHandler.WithinBounds
                        onTapped: (eventPoint) => {
                            assetContextMenu.showAt(
                                eventPoint.position.x,
                                eventPoint.position.y,
                                model.asset_id,
                                model.name,
                                model.path,
                                model.kind || "Data"
                            );
                        }
                    }

                    // Left color accent bar
                    Rectangle {
                        width: 3
                        height: parent.height
                        color: model.kind === "Video" ? "#4a9eff" :
                               model.kind === "Audio" ? "#4adf9e" :
                               model.kind === "Image" ? "#e09e4a" : "#888888"
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        spacing: 8

                        Text {
                            text: model.kind === "Video" ? "🎞" :
                                  model.kind === "Audio" ? "🎵" :
                                  model.kind === "Image" ? "🖼" : "📄"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: model.name
                            color: root.textPri
                            font.pixelSize: 12
                            font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: delegateRoot.width - 70
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#1e1e28"
                    }

                    // Drag ghost highlight
                    Rectangle {
                        anchors.fill: parent
                        color: "#404a9eff"
                        radius: 2
                        visible: dragHandler.active
                    }
                }
            }
        }
        // Bottom spacing reserved
        Item {
            Layout.fillWidth: true
            height: 10
        }
    }
}
