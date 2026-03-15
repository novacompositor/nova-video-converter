import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs // For FileDialog
import "../components"


Item {
    id: root
    focus: true

    property string activeVideoResource: ""
    property bool isPlaying: false
    property double currentTimeMs: 0
    property double durationMs: 10000 // Default 10 seconds for MVP
    property string activeCompositionId: ""
    
    // NLE Sequence Tracking
    property string activeSequenceId: ""
    property string activeSequenceName: ""
    property var activeSequenceData: null
    property var allSequences: []

    // Active Tool: "select" | "razor"
    property string activeTool: "select"

    // Selection state
    property string selectedClipId: ""

    // Viewer mode: "program" (sequence) | "source" (raw asset)
    property string viewerMode: "program"
    property string sourceAssetPath: "" // last asset clicked in Media Bin

    // Timeline View Options
    property real timeScale: 100 // pixels per second
    property real trackHeaderWidth: 200
    property real visualTimeMs: 0 // Instant UI property for smooth playhead

    Timer {
        id: dispatchTimer
        interval: 10 // Let the current JS event loop finish
        repeat: false
        property var pendingCommands: []
        onTriggered: {
            for (let i = 0; i < pendingCommands.length; i++) {
                appBridge.dispatchCommand(pendingCommands[i]);
            }
            pendingCommands = [];
        }
        function queueCommand(cmdStr) {
            let arr = pendingCommands;
            arr.push(cmdStr);
            pendingCommands = arr;
            start();
        }
    }
    
    Timer {
        id: scrubTimer
        interval: 33 // ~30 fps scrub updates
        repeat: false
        property real targetTimeMs: 0
        onTriggered: {
            root.currentTimeMs = targetTimeMs;
        }
    }

    onActiveSequenceIdChanged: {
        if (allSequences && Array.isArray(allSequences)) {
            for (let seq of allSequences) {
                if (seq.id === activeSequenceId) {
                    activeSequenceData = seq;
                    return;
                }
            }
        }
        activeSequenceData = null;
    }

    Keys.onSpacePressed: {
        root.isPlaying = !root.isPlaying;
        event.accepted = true;
    }

    // Tool hotkeys
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_V) {
            root.activeTool = "select";
            event.accepted = true;
        } else if (event.key === Qt.Key_C) {
            root.activeTool = "razor";
            event.accepted = true;
        } else if ((event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace)
                   && root.selectedClipId !== "" && root.activeSequenceId !== "") {
            dispatchTimer.queueCommand(JSON.stringify({
                type: "RemoveClipFromSequence",
                payload: {
                    sequence_id: root.activeSequenceId,
                    clip_id: root.selectedClipId
                }
            }));
            root.selectedClipId = "";
            event.accepted = true;
        }
    }

    Timer {
        id: playbackTimer
        interval: 33 // ~30 fps
        running: root.isPlaying
        repeat: true
        onTriggered: {
            root.currentTimeMs += 33;
            if (root.currentTimeMs >= root.durationMs) {
                root.currentTimeMs = 0;
                root.isPlaying = false; // Stop at end
            }
            root.visualTimeMs = root.currentTimeMs;
        }
    }

    Component.onCompleted: {
        // Initialization if needed
    }

    Connections {
        target: appBridge
        function onEngineEventReceived(eventJson) {
            try {
                let event = JSON.parse(eventJson);
                if (event && event.type === "ProjectChanged" && event.first_video_path) {
                    activeVideoResource = event.first_video_path;
                    console.log("QML received video path: " + activeVideoResource);
                }
            } catch (e) {
                console.error("Failed to parse event JSON:", e);
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical

        handle: Rectangle {
            implicitHeight: 4
            color: "#2a2a38"
        }

        // Top half: Media Bin (left) and Viewer (right)
        SplitView {
            SplitView.fillHeight: true
            SplitView.minimumHeight: 300
            SplitView.fillWidth: true
            orientation: Qt.Horizontal

            handle: Rectangle {
                implicitWidth: 4
                color: "#2a2a38"
            }

            // Media Bin
            Rectangle {
                SplitView.preferredWidth: 350
                SplitView.minimumWidth: 200
                color: "#1a1a24"

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

                FileDialog {
                    id: importMediaDialog
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
                            onAct: importMediaDialog.open() }
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
                        let res = appBridge.dispatchCommand(JSON.stringify(cmd)); console.log("CreateSequence result: " + res);
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    color: "#2a2a35"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        Text {
                            text: "MEDIA BIN"
                            color: "#8888a0"
                            font.pixelSize: 11
                            font.family: "Inter"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                }
                
                // ── Dark context menu for assets ──
                Popup {
                    id: editRoomContextMenu
                    width: 242
                    padding: 5
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                    // asset data
                    property string assetId:   ""
                    property string assetName: ""
                    property string assetPath: ""
                    property string assetKind: ""

                    function showAt(mx, my, id, name, path, kind) {
                        assetId   = id;
                        assetName = name;
                        assetPath = path;
                        assetKind = kind;
                        x = mx; y = my;
                        open();
                    }

                    background: Rectangle {
                        color: "#1c1c2a"; border.color: "#3d3d56"; border.width: 1; radius: 7
                    }

                    contentItem: Column {
                        spacing: 1; topPadding: 4; bottomPadding: 4

                        // ─ row helper ─
                        component MRow: Rectangle {
                            property string label: ""
                            property string icon: ""
                            property color  clr: "#8888aa"
                            property bool   danger: false
                            signal act()
                            width: 232; height: 34; radius: 5
                            color: mra.containsMouse ? (danger ? "#321818" : "#252540") : "transparent"
                            Row { anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                Text { text: icon; color: danger ? "#ff6060" : clr; font.pixelSize: 14; width: 18; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter }
                                Text { text: label; color: danger ? "#ff7070" : "#d4d4ec"; font.pixelSize: 13; font.family: "Inter"; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: mra; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { editRoomContextMenu.close(); act(); } }
                        }

                        MRow { label: "Open in Viewer"; icon: "▶"; clr: "#4a9eff"
                            onAct: { root.activeVideoResource = editRoomContextMenu.assetPath; root.currentTimeMs = 0; } }

                        Rectangle { width: 222; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter }

                        MRow { label: "New Composition from Clip"; icon: "⊞"; clr: "#4adf9e"
                            visible: editRoomContextMenu.assetKind !== "Sequence"
                            onAct: {
                                if (editRoomContextMenu.assetId !== "")
                                    appBridge.dispatchCommand(JSON.stringify({ type: "CreateCompFromAsset", payload: { asset_id: editRoomContextMenu.assetId } }));
                            }
                        }

                        Rectangle { width: 222; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter; visible: editRoomContextMenu.assetKind !== "Sequence" }

                        MRow { label: "Clip Interpretation..."; icon: "⚙"; clr: "#aaaacc"
                            visible: editRoomContextMenu.assetKind !== "Sequence"
                            onAct: { console.log("Properties for", editRoomContextMenu.assetName); } }

                        MRow { label: "Sequence Settings..."; icon: "⚙"; clr: "#aaaacc"
                            visible: editRoomContextMenu.assetKind === "Sequence"
                            onAct: { console.log("Sequence settings for", editRoomContextMenu.assetName); } }

                        Rectangle { width: 222; height: 1; color: "#2d2d45"; anchors.horizontalCenter: parent.horizontalCenter }

                        MRow { label: "Remove from Project"; icon: "✕"; danger: true
                            onAct: {
                                if (editRoomContextMenu.assetId !== "") {
                                    appBridge.dispatchCommand(JSON.stringify({ type: "RemoveAsset", payload: { asset_id: editRoomContextMenu.assetId } }));
                                    for (let i = 0; i < localAssetModel.count; i++) {
                                        if (localAssetModel.get(i).asset_id === editRoomContextMenu.assetId) { localAssetModel.remove(i); break; }
                                    }
                                }
                            }
                        }
                    }
                }

                // Dynamic asset list
                ListView {
                    anchors.fill: parent
                    anchors.topMargin: 32
                    clip: true
                    
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: (eventPoint) => {
                            binContextMenu.showAt(eventPoint.position.x, eventPoint.position.y);
                        }
                    }

                    model: ListModel {
                        id: localAssetModel
                    }

                    Connections {
                        target: appBridge
                        function onEngineEventReceived(eventJson) {
                            try {
                                let response = JSON.parse(eventJson);
                                if (response && response.events && Array.isArray(response.events)) {
                                    for (let ev of response.events) {
                                        if (ev.type === "AssetImported" && ev.payload) {
                                            // Handle dynamically or ignore and let StateSynced handle it.
                                            // Since ProjectChanged fires alongside AssetImported, StateSynced will rebuild it.
                                        } else if (ev.type === "ProjectChanged") {
                                            appBridge.dispatchCommand(JSON.stringify({ type: "SyncState" }));
                                        } else if (ev.type === "StateSynced" && ev.payload && ev.payload.project) {
                                            let proj = ev.payload.project;
                                            localAssetModel.clear();
                                            // Add Sequences
                                            if (proj.sequences && Array.isArray(proj.sequences)) {
                                                root.allSequences = proj.sequences;
                                                for (let seq of proj.sequences) {
                                                    localAssetModel.append({
                                                        name: seq.name,
                                                        path: "",
                                                        kind: "Sequence",
                                                        asset_id: seq.id
                                                    });
                                                    
                                                    if (seq.id === root.activeSequenceId) {
                                                        root.activeSequenceData = seq;
                                                    }
                                                }
                                            }
                                            // Add Assets
                                            if (proj.assets && Array.isArray(proj.assets)) {
                                                for (let asset of proj.assets) {
                                                    localAssetModel.append({
                                                        name: asset.name,
                                                        path: asset.path,
                                                        kind: asset.kind || "Data",
                                                        asset_id: asset.asset_id || asset.id || ""
                                                    });
                                                }
                                            }
                                            if (proj.compositions && proj.compositions.length > 0) {
                                                root.activeCompositionId = proj.compositions[0].id;
                                            }
                                        }
                                    }
                                }
                            } catch (e) {}
                        }
                    }

                    // Empty state hint
                    Text {
                        anchors.centerIn: parent
                        text: "No media. Use Import Media below."
                        color: "#555566"
                        font.pixelSize: 11
                        font.family: "Inter"
                        visible: localAssetModel.count === 0
                    }

                    delegate: Item {
                        id: editDelegateRoot
                        width: ListView.view.width
                        height: 30

                        Rectangle {
                            id: editDelegateRect
                            anchors.fill: parent
                            color: hoverHandler.hovered ? "#252535" : (index % 2 === 0 ? "transparent" : "#1c1c28")

                            // ── Drag & Drop support ──
                            Drag.active: dragHandler.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction
                            Drag.mimeData: ({
                                "application/x-nova-asset-id": model.asset_id,
                                "text/plain": model.name
                            })

                            DragHandler {
                                id: dragHandler
                                acceptedButtons: Qt.LeftButton
                                grabPermissions: PointerHandler.CanTakeOverFromAnything
                            }

                            HoverHandler { id: hoverHandler }

                            TapHandler {
                                id: doubleTapHandler
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.WithinBounds
                                onDoubleTapped: {
                                    if (model.kind === "Sequence") {
                                        root.activeSequenceId = model.asset_id;
                                        root.activeSequenceName = model.name;
                                    } else {
                                        root.sourceAssetPath = model.path;
                                        root.activeVideoResource = model.path;
                                        root.currentTimeMs = 0;
                                    }
                                }
                                onTapped: {
                                    // Single click: store as source asset for Source Monitor
                                    if (model.kind !== "Sequence" && model.path !== "") {
                                        root.sourceAssetPath = model.path;
                                    }
                                }
                            }

                            TapHandler {
                                id: rightClickHandler
                                acceptedButtons: Qt.RightButton
                                gesturePolicy: TapHandler.WithinBounds
                                onTapped: (eventPoint) => {
                                    editRoomContextMenu.showAt(
                                        eventPoint.position.x,
                                        eventPoint.position.y,
                                        model.asset_id,
                                        model.name,
                                        model.path,
                                        model.kind || "Data"
                                    );
                                }
                            }

                            // Color bar by kind
                            Rectangle {
                                width: 3; height: parent.height
                                color: model.kind === "Video" ? "#4a9eff" :
                                       model.kind === "Audio" ? "#4adf9e" :
                                       model.kind === "Image" ? "#e09e4a" : "#888888"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 8
                                Text {
                                    text: model.kind === "Video" ? "🎞" :
                                          model.kind === "Audio" ? "🎵" :
                                          model.kind === "Image" ? "🖼" : "📄"
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: model.name
                                    color: "#e8e8ea"
                                    font.pixelSize: 12
                                    font.family: "Inter"
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: editDelegateRoot.width - 60
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
            }

            // Viewer — Source / Program Monitor
            Rectangle {
                SplitView.fillWidth: true
                color: "#0f0f14"

                // ── Monitor header with Source/Program toggle ──
                Rectangle {
                    id: monitorHeader
                    width: parent.width
                    height: 32
                    color: "#1a1a24"
                    z: 5

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Rectangle {
                            width: 90; height: 24; radius: 4
                            color: root.viewerMode === "source" ? "#3a5a8a" : "#252535"
                            border.color: root.viewerMode === "source" ? "#4a9eff" : "transparent"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "Source"
                                color: root.viewerMode === "source" ? "#ffffff" : "#7070a0"
                                font.pixelSize: 12; font.family: "Inter"; font.bold: root.viewerMode === "source"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.viewerMode = "source"
                            }
                        }

                        Rectangle {
                            width: 90; height: 24; radius: 4
                            color: root.viewerMode === "program" ? "#3a5a8a" : "#252535"
                            border.color: root.viewerMode === "program" ? "#4a9eff" : "transparent"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "Program"
                                color: root.viewerMode === "program" ? "#ffffff" : "#7070a0"
                                font.pixelSize: 12; font.family: "Inter"; font.bold: root.viewerMode === "program"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.viewerMode = "program"
                            }
                        }
                    }
                }

                // ── Video canvas ──
                Rectangle {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 16 // offset for the 32px header
                    width: Math.min(parent.width - 40, (parent.height - 72) * 16/9)
                    height: width * 9/16
                    color: "#000000"
                    border.color: "#2a2a35"
                    border.width: 1

                    // Program Monitor image (sequence playback)
                    Image {
                        id: videoFrame
                        anchors.fill: parent
                        anchors.margins: 1
                        source: {
                            if (root.viewerMode === "program" && root.activeVideoResource !== "")
                                return "image://videoframe/" + root.activeVideoResource + "?time=" + Math.floor(root.currentTimeMs);
                            if (root.viewerMode === "source" && root.sourceAssetPath !== "")
                                return "image://videoframe/" + root.sourceAssetPath + "?time=0";
                            return "";
                        }
                        fillMode: Image.PreserveAspectFit
                        visible: source !== ""
                        cache: false
                    }

                    // Empty state label
                    Text {
                        anchors.centerIn: parent
                        text: root.viewerMode === "program"
                              ? (root.activeSequenceId === "" ? "NO SEQUENCE SELECTED" : "")
                              : (root.sourceAssetPath === "" ? "CLICK AN ASSET TO PREVIEW" : "")
                        color: "#4a4a5a"
                        font.pixelSize: 16
                        font.family: "Inter"
                        font.letterSpacing: 2
                        visible: text !== ""
                    }

                    // Monitor mode label overlay
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 8
                        text: root.viewerMode === "source" ? "SOURCE" : "PROGRAM"
                        color: "#3a3a5a"
                        font.pixelSize: 10
                        font.family: "Inter"
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                }
            }
        }

        // Bottom half: NLE Timeline
        Rectangle {
            SplitView.preferredHeight: 300
            SplitView.minimumHeight: 150
            SplitView.fillWidth: true
            color: "#161620"

            // ── Timeline header: toolbar + name bar + ruler ──
            Rectangle {
                id: timelineHeader
                width: parent.width
                height: 72
                color: "#1a1a24"
                z: 10

                // Tool Toolbar (28px)
                Rectangle {
                    id: toolToolbar
                    width: parent.width; height: 28
                    color: "#151520"
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 8
                        spacing: 4
                        component ToolBtn: Rectangle {
                            property string toolId: ""
                            property string label: ""
                            property string shortcut: ""
                            width: 76; height: 22; radius: 4
                            color: root.activeTool === toolId ? "#2e4a70" : "#22222e"
                            border.color: root.activeTool === toolId ? "#4a9eff" : "transparent"
                            border.width: 1
                            Row {
                                anchors.centerIn: parent; spacing: 5
                                Text { text: shortcut; color: root.activeTool === toolId ? "#7ab8ff" : "#555578"; font.pixelSize: 10; font.bold: true; font.family: "Inter" }
                                Text { text: label;    color: root.activeTool === toolId ? "#ffffff"  : "#9090b0"; font.pixelSize: 11;                    font.family: "Inter" }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.activeTool = toolId; root.forceActiveFocus(); } }
                        }
                        ToolBtn { toolId: "select"; label: "Select"; shortcut: "V" }
                        ToolBtn { toolId: "razor";  label: "Razor";  shortcut: "C" }
                    }
                }

                // Sequence name bar (20px at y=28)
                Rectangle {
                    y: 28; width: parent.width; height: 20
                    color: "#22222d"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 12
                        text: root.activeSequenceName !== "" ? root.activeSequenceName.toUpperCase() : "NO SEQUENCE SELECTED"
                        color: "#8888a0"; font.pixelSize: 11; font.family: "Inter"; font.bold: true
                    }
                }

                // Timecode Ruler (24px at y=48)
                Rectangle {
                    y: 48; width: parent.width; height: 24
                    color: "#1e1e28"

                    Canvas {
                        id: timeRuler
                        anchors.left: parent.left; anchors.leftMargin: root.trackHeaderWidth
                        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var secondsToDraw = Math.ceil(width / root.timeScale);
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            for (var s = 0; s <= secondsToDraw; s++) {
                                var xPos = s * root.timeScale;
                                var h2 = Math.floor(s / 3600);
                                var m  = Math.floor((s % 3600) / 60);
                                var sc = s % 60;
                                var ts = (h2 < 10 ? "0"+h2 : h2)+":"+(m < 10 ? "0"+m : m)+":"+(sc < 10 ? "0"+sc : sc)+":00";
                                ctx.moveTo(xPos, height - 8);
                                ctx.lineTo(xPos, height);
                                ctx.fillStyle = "#8888a0"; ctx.font = "10px Inter";
                                ctx.fillText(ts, xPos + 4, height - 12);
                            }
                            ctx.strokeStyle = "#4a4a5a"; ctx.stroke();
                        }
                        Connections { target: root; function onTimeScaleChanged() { timeRuler.requestPaint(); } }
                    }

                    // Ruler scrub MouseArea
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        function updatePlayhead(mouse) {
                            if (mouse.x >= root.trackHeaderWidth) {
                                root.forceActiveFocus();
                                let mouseSecs = (mouse.x - root.trackHeaderWidth) / root.timeScale;
                                let clamped = Math.max(0, Math.min(mouseSecs * 1000, root.durationMs));
                                root.visualTimeMs = clamped;
                                scrubTimer.targetTimeMs = clamped;
                                if (!scrubTimer.running) scrubTimer.start();
                            }
                        }
                        onPressed:         (mouse) => { root.isPlaying = false; updatePlayhead(mouse); }
                        onPositionChanged: (mouse) => { if (pressed) updatePlayhead(mouse); }
                    }
                }
            }

            // ── Scrollable tracks area (starts below header) ──
            Flickable {
                id: tracksFlickable
                anchors.fill: parent
                anchors.topMargin: 72   // exactly the header height
                contentHeight: trackColumn.height
                clip: true
                visible: root.activeSequenceId !== ""

                DropArea {
                    id: timelineDropArea
                    anchors.fill: parent

                    onEntered: (drag) => { drag.accept(); }

                    onDropped: (drop) => {
                        let assetId  = drop.getDataAsString("application/x-nova-asset-id");
                        let assetName = drop.getDataAsString("text/plain");
                        console.log("QML: onDropped - assetId=", assetId, " seq=", root.activeSequenceId);
                        if (assetId && root.activeSequenceId !== "") {
                            let track_index = 0;
                            if      (drop.y < 38)  track_index = 0;
                            else if (drop.y < 76)  track_index = 1;
                            else if (drop.y < 114) track_index = 2;
                            else if (drop.y < 166) track_index = 3;
                            else                   track_index = 4;

                            let dropXPos = Math.max(0, drop.x - root.trackHeaderWidth);
                            let tick = Math.floor((dropXPos / root.timeScale) * 30);

                            let cmd = {
                                type: "AddClipToSequence",
                                payload: {
                                    sequence_id: root.activeSequenceId,
                                    track_index: track_index,
                                    asset_id: assetId,
                                    start_time: { value: tick, rate: 30 }
                                }
                            };
                            dispatchTimer.queueCommand(JSON.stringify(cmd));
                            drop.accept();
                        } else {
                            console.warn("QML: assetId empty or no active sequence.");
                        }
                    }
                }

                Row {
                    id: trackRow
                    width: parent.width
                    height: trackColumn.height

                    // Track headers
                    Column {
                        id: headerColumn
                        width: 200
                        spacing: 2
                        Repeater {
                            model: ["V3", "V2", "V1", "A1", "A2"]
                            Rectangle {
                                required property int index
                                required property string modelData
                                width: 200
                                height: index >= 3 ? 50 : 36
                                color: "#1e1e28"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left; anchors.leftMargin: 12
                                    text: modelData; color: "#e8e8ea"
                                    font.pixelSize: 12; font.family: "Inter"; font.bold: true
                                }
                            }
                        }
                    }

                    // Clip tracks
                    Column {
                        id: trackColumn
                        width: parent.width - 200
                        spacing: 2

                        Repeater {
                            id: trackRepeater
                            model: root.activeSequenceData
                                   ? root.activeSequenceData.video_tracks.concat(root.activeSequenceData.audio_tracks)
                                   : []

                            Rectangle {
                                id: trackRect
                                width: trackColumn.width
                                property bool isVideoTrack: root.activeSequenceData && index < root.activeSequenceData.video_tracks.length
                                height: isVideoTrack ? 36 : 50
                                color: "#161620"
                                property bool hasDraggedClip: false
                                z: hasDraggedClip ? 100 : 1

                                Repeater {
                                    model: modelData.clips

                                    Rectangle {
                                        id: clipRect
                                        property real startSecs:    modelData.start_time ? (modelData.start_time.value / modelData.start_time.rate) : 0
                                        property real durationSecs: modelData.duration   ? (modelData.duration.value   / modelData.duration.rate)   : 0

                                        x: startSecs * root.timeScale
                                        y: 2
                                        width:  Math.max(1, durationSecs * root.timeScale)
                                        height: trackRect.isVideoTrack ? 32 : 46
                                        z: 10

                                        property bool isSelected: root.selectedClipId === modelData.id

                                        color: clipMouseArea.drag.active
                                            ? "#6a8aba"
                                            : (trackRect.isVideoTrack
                                               ? (isSelected ? "#4a7ab8" : "#2d4a70")
                                               : (isSelected ? "#3a8a6a" : "#1e5242"))
                                        radius: 3

                                        // Selection border
                                        Rectangle {
                                            anchors.fill: parent; color: "transparent"; radius: 3; z: 20
                                            border.color: clipRect.isSelected ? "#ffffff" : "transparent"
                                            border.width: 1
                                        }

                                        // Clip name
                                        Text {
                                            anchors.left: parent.left; anchors.leftMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name || ""; color: "#ddeeff"
                                            font.pixelSize: 10; font.family: "Inter"
                                            elide: Text.ElideRight; width: clipRect.width - 20
                                        }

                                        // Main drag/select/razor MouseArea
                                        MouseArea {
                                            id: clipMouseArea
                                            anchors.fill: parent
                                            anchors.leftMargin: 8; anchors.rightMargin: 8
                                            drag.target: root.activeTool === "select" ? clipRect : undefined
                                            drag.axis: Drag.XAndYAxis
                                            cursorShape: root.activeTool === "razor" ? Qt.SplitHCursor : Qt.ArrowCursor

                                            property real startRectX: 0
                                            property real startRectY: 0

                                            onPressed: (mouse) => {
                                                root.forceActiveFocus();
                                                if (root.activeTool === "select") {
                                                    root.selectedClipId = modelData.id;
                                                    startRectX = clipRect.x;
                                                    startRectY = clipRect.y;
                                                    trackRect.hasDraggedClip = true;
                                                } else if (root.activeTool === "razor") {
                                                    let clickSecs = startSecs + ((mouse.x + 8) / root.timeScale);
                                                    let splitTick = Math.floor(clickSecs * 30);
                                                    let clipStartTick = modelData.start_time ? modelData.start_time.value : 0;
                                                    let clipDurTick   = modelData.duration   ? modelData.duration.value   : 0;
                                                    if (splitTick > clipStartTick && splitTick < clipStartTick + clipDurTick) {
                                                        dispatchTimer.queueCommand(JSON.stringify({
                                                            type: "SplitClipInSequence",
                                                            payload: {
                                                                sequence_id: root.activeSequenceId,
                                                                clip_id: modelData.id,
                                                                split_time: { value: splitTick, rate: 30 }
                                                            }
                                                        }));
                                                    }
                                                    mouse.accepted = true;
                                                }
                                            }

                                            onReleased: {
                                                trackRect.hasDraggedClip = false;
                                                if (root.activeTool !== "select") return;
                                                if (clipRect.x === startRectX && clipRect.y === startRectY) return;

                                                let globalPos = clipRect.parent.mapToItem(trackColumn, clipRect.x, clipRect.y);
                                                let droppedTrackIdx = 0;
                                                if      (globalPos.y < 38)  droppedTrackIdx = 0;
                                                else if (globalPos.y < 76)  droppedTrackIdx = 1;
                                                else if (globalPos.y < 114) droppedTrackIdx = 2;
                                                else if (globalPos.y < 166) droppedTrackIdx = 3;
                                                else                         droppedTrackIdx = 4;

                                                let numVideo = root.activeSequenceData.video_tracks.length;
                                                let isMovingToAudio = droppedTrackIdx >= numVideo;
                                                if ((trackRect.isVideoTrack && isMovingToAudio) || (!trackRect.isVideoTrack && !isMovingToAudio)) {
                                                    console.warn("QML: Cannot move clip between audio and video tracks.");
                                                    clipRect.x = startRectX; clipRect.y = startRectY;
                                                    return;
                                                }

                                                let tick = Math.max(0, Math.floor((globalPos.x / root.timeScale) * 30));
                                                let deltaTick = tick - Math.max(0, Math.floor(startSecs * 30));
                                                let allTracks = root.activeSequenceData.video_tracks.concat(root.activeSequenceData.audio_tracks);
                                                let targetCmds = [];

                                                for (let tIdx = 0; tIdx < allTracks.length; tIdx++) {
                                                    for (let c of allTracks[tIdx].clips) {
                                                        if (c.item.asset_id === modelData.item.asset_id) {
                                                            let destTrack = (c.id === modelData.id) ? droppedTrackIdx : tIdx;
                                                            let newTick = Math.max(0, (c.start_time ? c.start_time.value : 0) + deltaTick);
                                                            targetCmds.push({
                                                                type: "MoveClipInSequence",
                                                                payload: {
                                                                    sequence_id: root.activeSequenceId,
                                                                    clip_id: c.id,
                                                                    new_track_index: destTrack,
                                                                    new_start_time: { value: newTick, rate: 30 }
                                                                }
                                                            });
                                                        }
                                                    }
                                                }

                                                clipRect.x = startRectX; clipRect.y = startRectY;
                                                dispatchTimer.interval = 50;
                                                for (let cmd of targetCmds) dispatchTimer.queueCommand(JSON.stringify(cmd));
                                            }
                                        }

                                        // Left trim handle
                                        Rectangle {
                                            x: 0; y: 0; width: 8; height: parent.height; radius: 3; z: 15
                                            color: lth.containsMouse ? "#99ffffff" : "#33ffffff"
                                            HoverHandler { id: lth }
                                            property real origStart: 0; property real origDur: 0
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                                                property real px: 0
                                                onPressed: (m) => { root.selectedClipId = modelData.id; px = mapToItem(null,m.x,0).x; parent.origStart = clipRect.startSecs; parent.origDur = clipRect.durationSecs; }
                                                onPositionChanged: (m) => {
                                                    if (!pressed) return;
                                                    let d = (mapToItem(null,m.x,0).x - px) / root.timeScale;
                                                    let ns = Math.max(0, parent.origStart + d);
                                                    let nd = Math.max(0.1, parent.origDur - (ns - parent.origStart));
                                                    clipRect.x = ns * root.timeScale; clipRect.width = Math.max(8, nd * root.timeScale);
                                                }
                                                onReleased: {
                                                    clipRect.x = Qt.binding(() => clipRect.startSecs * root.timeScale);
                                                    clipRect.width = Qt.binding(() => Math.max(1, clipRect.durationSecs * root.timeScale));
                                                }
                                            }
                                        }

                                        // Right trim handle
                                        Rectangle {
                                            anchors.right: parent.right; y: 0; width: 8; height: parent.height; radius: 3; z: 15
                                            color: rth.containsMouse ? "#99ffffff" : "#33ffffff"
                                            HoverHandler { id: rth }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                                                property real px: 0; property real ow: 0
                                                onPressed: (m) => { root.selectedClipId = modelData.id; px = mapToItem(null,m.x,0).x; ow = clipRect.width; }
                                                onPositionChanged: (m) => {
                                                    if (!pressed) return;
                                                    clipRect.width = Math.max(8, ow + (mapToItem(null,m.x,0).x - px));
                                                }
                                                onReleased: {
                                                    clipRect.width = Qt.binding(() => Math.max(1, clipRect.durationSecs * root.timeScale));
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Playhead — direct child of bottom panel, absolutely positioned ──
            // Sits outside the Flickable so it doesn't scroll with tracks.
            Rectangle {
                id: playhead
                x: root.trackHeaderWidth + ((root.visualTimeMs / 1000) * root.timeScale)
                y: 48              // top of the ruler (toolbar=28 + nameBar=20)
                width: 2
                height: parent.height - 48
                color: "#ff3333"
                z: 200             // above header (z=10) and tracks
                visible: root.activeSequenceId !== ""

                // Triangle cap
                Canvas {
                    width: 13; height: 13
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = "#ff3333";
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        ctx.lineTo(width, 0);
                        ctx.lineTo(width, height - 5);
                        ctx.lineTo(width/2, height);
                        ctx.lineTo(0, height - 5);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
        }
    }
}


            SplitView.fillWidth: true
            color: "#161620"

            Rectangle {
                id: timelineHeader
                width: parent.width
                height: 72
                color: "#1a1a24"
                z: 10

                // ── Tool Toolbar ──
                Rectangle {
                    id: toolToolbar
                    width: parent.width
                    height: 28
                    color: "#151520"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 4

                        component ToolBtn: Rectangle {
                            property string toolId: ""
                            property string label: ""
                            property string shortcut: ""
                            width: 72; height: 22; radius: 4
                            color: root.activeTool === toolId ? "#2e4a70" : "#22222e"
                            border.color: root.activeTool === toolId ? "#4a9eff" : "transparent"
                            border.width: 1
                            Row {
                                anchors.centerIn: parent; spacing: 5
                                Text { text: shortcut; color: root.activeTool === toolId ? "#7ab8ff" : "#5555780"; font.pixelSize: 10; font.bold: true; font.family: "Inter" }
                                Text { text: label; color: root.activeTool === toolId ? "#ffffff" : "#9090b0"; font.pixelSize: 11; font.family: "Inter" }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.activeTool = toolId; root.forceActiveFocus(); } }
                        }

                        ToolBtn { toolId: "select"; label: "Select";  shortcut: "V" }
                        ToolBtn { toolId: "razor";  label: "Razor";   shortcut: "C" }
                    }
                }

                // Sequence name bar
                Rectangle {
                    y: 28
                    width: parent.width
                    height: 20
                    color: "#22222d"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        text: root.activeSequenceName !== "" ? root.activeSequenceName.toUpperCase() : "NO SEQUENCE SELECTED"
                        color: "#8888a0"
                        font.pixelSize: 11
                        font.family: "Inter"
                        font.bold: true
                    }
                }
                
                // Timecode Ruler
                Rectangle {
                    y: 48
                    width: parent.width
                    height: 24
                    color: "#1e1e28"
                    
                    Canvas {
                        id: timeRuler
                        anchors.left: parent.left
                        anchors.leftMargin: root.trackHeaderWidth
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            
                            // Draw time ticks
                            var secondsToDraw = Math.ceil(width / root.timeScale);
                            
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            
                            for (var s = 0; s <= secondsToDraw; s++) {
                                var xPos = s * root.timeScale;
                                
                                // Format time string HH:MM:SS:00
                                var h = Math.floor(s / 3600);
                                var m = Math.floor((s % 3600) / 60);
                                var sec = s % 60;
                                var timeStr = (h < 10 ? "0" + h : h) + ":" + 
                                            (m < 10 ? "0" + m : m) + ":" + 
                                            (sec < 10 ? "0" + sec : sec) + ":00";
                                            
                                ctx.moveTo(xPos, height - 8);
                                ctx.lineTo(xPos, height);
                                
                                ctx.fillStyle = "#8888a0";
                                ctx.font = "10px Inter";
                                ctx.fillText(timeStr, xPos + 4, height - 12);
                            }
                            ctx.strokeStyle = "#4a4a5a";
                            ctx.stroke();
                        }
                        
                        Connections {
                            target: root
                            function onTimeScaleChanged() { timeRuler.requestPaint(); }
                        }
                    }

                    // Unified MouseArea for playhead scrubbing
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        
                        function updatePlayhead(mouse) {
                            if (mouse.x >= root.trackHeaderWidth) {
                                root.forceActiveFocus();
                                let mouseSecs = (mouse.x - root.trackHeaderWidth) / root.timeScale;
                                let newTimeMs = mouseSecs * 1000;
                                let clamped = Math.max(0, Math.min(newTimeMs, root.durationMs));
                                root.visualTimeMs = clamped; // Instant playhead moving
                                scrubTimer.targetTimeMs = clamped;
                                if (!scrubTimer.running) scrubTimer.start();
                            }
                        }

                        onPressed: (mouse) => {
                            root.isPlaying = false; // Pause when scrubbing
                            updatePlayhead(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                updatePlayhead(mouse);
                            }
                        }
                    }
                }
            }

            // Tracks area
            Flickable {
                anchors.fill: parent
                anchors.topMargin: 56
                contentHeight: trackColumn.height
                clip: true
                visible: root.activeSequenceId !== ""

                DropArea {
                    id: timelineDropArea
                    anchors.fill: parent

                    onEntered: (drag) => {
                        console.log("QML: DropArea entered. Formats:", JSON.stringify(drag.formats));
                        drag.accept();
                    }

                    onExited: {
                        console.log("QML: DropArea exited");
                    }

                    onDropped: (drop) => {
                        let assetId = drop.getDataAsString("application/x-nova-asset-id");
                        let assetName = drop.getDataAsString("text/plain");
                        console.log("QML: onDropped - assetId=", assetId, " seq=", root.activeSequenceId);
                        if (assetId && root.activeSequenceId !== "") {
                            console.log("QML: Dropped asset " + assetId + " onto Sequence!");

                            let track_index = 0;
                            if (drop.y < 38) track_index = 0;
                            else if (drop.y < 76) track_index = 1;
                            else if (drop.y < 114) track_index = 2;
                            else if (drop.y < 166) track_index = 3;
                            else track_index = 4;

                            // Calculate tick from drop.x using timeScale
                            let dropXPos = Math.max(0, drop.x - root.trackHeaderWidth);
                            let dropSecs = dropXPos / root.timeScale;
                            let tick = Math.floor(dropSecs * 30); // Assuming 30fps base

                            let cmd = {
                                type: "AddClipToSequence",
                                payload: {
                                    sequence_id: root.activeSequenceId,
                                    track_index: track_index,
                                    asset_id: assetId,
                                    start_time: { value: tick, rate: 30 }
                                }
                            };
                            dispatchTimer.queueCommand(JSON.stringify(cmd));
                            drop.accept();
                        } else {
                            console.warn("QML: assetId empty or no active sequence.");
                        }
                    }
                }

                Row {
                    id: trackRow
                    width: parent.width
                    height: trackColumn.height

                    // Track headers
                    Column {
                        id: headerColumn
                        width: 200
                        spacing: 2
                        
                        Repeater {
                            model: ["V3", "V2", "V1", "A1", "A2"]
                            Rectangle {
                                required property int index
                                required property string modelData
                                
                                width: 200
                                height: index >= 3 ? 50 : 36 // Taller audio tracks
                                color: "#1e1e28"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    text: modelData
                                    color: "#e8e8ea"
                                    font.pixelSize: 12
                                    font.family: "Inter"
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // Timeline items (Clips)
                    Column {
                        id: trackColumn
                        width: parent.width - 200
                        spacing: 2
                        
                        Repeater {
                            id: trackRepeater
                            // Combine video and audio tracks if activeSequenceData is present
                            model: root.activeSequenceData ? root.activeSequenceData.video_tracks.concat(root.activeSequenceData.audio_tracks) : []
                            
                            Rectangle {
                                id: trackRect
                                width: trackColumn.width
                                // Audio tracks (index >= video_tracks.length) are taller
                                property bool isVideoTrack: root.activeSequenceData && index < root.activeSequenceData.video_tracks.length
                                height: isVideoTrack ? 36 : 50
                                color: "#161620"
                                property bool hasDraggedClip: false
                                z: hasDraggedClip ? 100 : 1
                                
                                Repeater {
                                    model: modelData.clips
                                    
                                    Rectangle {
                                        id: clipRect
                                        // Position and width based on seconds * timeScale
                                        property real startSecs: modelData.start_time ? (modelData.start_time.value / modelData.start_time.rate) : 0
                                        property real durationSecs: modelData.duration ? (modelData.duration.value / modelData.duration.rate) : 0

                                        x: startSecs * root.timeScale
                                        y: 2
                                        width: Math.max(1, durationSecs * root.timeScale)
                                        // Use track height minus margins
                                        height: trackRect.isVideoTrack ? 32 : 46
                                        z: 10 // Above track background

                                        property bool isSelected: root.selectedClipId === modelData.id

                                        // Clip body color
                                        color: clipMouseArea.drag.active
                                            ? "#6a8aba"
                                            : (trackRect.isVideoTrack
                                               ? (isSelected ? "#4a7ab8" : "#2d4a70")
                                               : (isSelected ? "#3a8a6a" : "#1e5242"))
                                        radius: 3

                                        // Selection border
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"
                                            border.color: clipRect.isSelected ? "#ffffff" : "transparent"
                                            border.width: 1
                                            radius: 3
                                            z: 20
                                        }

                                        // Clip name label
                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name || ""
                                            color: "#ddeeff"
                                            font.pixelSize: 10
                                            font.family: "Inter"
                                            elide: Text.ElideRight
                                            width: clipRect.width - 20
                                        }

                                        // ── Main clip drag/select/razor MouseArea ──
                                        MouseArea {
                                            id: clipMouseArea
                                            anchors.fill: parent
                                            anchors.leftMargin: 8   // leave room for trim handle
                                            anchors.rightMargin: 8  // leave room for trim handle

                                            // Drag only in select mode
                                            drag.target: root.activeTool === "select" ? clipRect : undefined
                                            drag.axis: Drag.XAndYAxis
                                            cursorShape: root.activeTool === "razor" ? Qt.SplitHCursor : Qt.ArrowCursor

                                            property real startRectX: 0
                                            property real startRectY: 0

                                            onPressed: (mouse) => {
                                                root.forceActiveFocus();
                                                if (root.activeTool === "select") {
                                                    root.selectedClipId = modelData.id;
                                                    startRectX = clipRect.x;
                                                    startRectY = clipRect.y;
                                                    trackRect.hasDraggedClip = true;
                                                } else if (root.activeTool === "razor") {
                                                    // Calculate split time from click position relative to clip start
                                                    let clickXInClip = mouse.x + clipMouseArea.anchors.leftMargin;
                                                    let clickSecs = startSecs + (clickXInClip / root.timeScale);
                                                    let splitTick = Math.floor(clickSecs * 30);
                                                    let clipStartTick = modelData.start_time ? modelData.start_time.value : 0;
                                                    let clipDurTick   = modelData.duration   ? modelData.duration.value   : 0;
                                                    // Guard: split must be inside the clip
                                                    if (splitTick > clipStartTick && splitTick < clipStartTick + clipDurTick) {
                                                        dispatchTimer.queueCommand(JSON.stringify({
                                                            type: "SplitClipInSequence",
                                                            payload: {
                                                                sequence_id: root.activeSequenceId,
                                                                clip_id: modelData.id,
                                                                split_time: { value: splitTick, rate: 30 }
                                                            }
                                                        }));
                                                    }
                                                    mouse.accepted = true;
                                                }
                                            }

                                            onReleased: {
                                                trackRect.hasDraggedClip = false;
                                                if (root.activeTool !== "select") return;
                                                if (clipRect.x !== startRectX || clipRect.y !== startRectY) {
                                                    // Map clip's item position to trackColumn to find new offset
                                                    let globalPos = clipRect.parent.mapToItem(trackColumn, clipRect.x, clipRect.y);

                                                    let droppedTrackIdx = 0;
                                                    if (globalPos.y < 38) droppedTrackIdx = 0;
                                                    else if (globalPos.y < 76) droppedTrackIdx = 1;
                                                    else if (globalPos.y < 114) droppedTrackIdx = 2;
                                                    else if (globalPos.y < 166) droppedTrackIdx = 3;
                                                    else droppedTrackIdx = 4;

                                                    let numVideoTracks = root.activeSequenceData.video_tracks.length;
                                                    let isMovingToAudio = droppedTrackIdx >= numVideoTracks;

                                                    // Validate move: video to video, audio to audio
                                                    if ((trackRect.isVideoTrack && isMovingToAudio) || (!trackRect.isVideoTrack && !isMovingToAudio)) {
                                                        console.warn("QML: Cannot move clip between audio and video tracks.");
                                                        clipRect.x = startRectX;
                                                        clipRect.y = startRectY;
                                                        return;
                                                    }

                                                    let droppedSecs = globalPos.x / root.timeScale;
                                                    let tick = Math.max(0, Math.floor(droppedSecs * 30));
                                                    let deltaTick = tick - Math.max(0, Math.floor(startSecs * 30));

                                                    let targetCmds = [];
                                                    let allTracks = root.activeSequenceData.video_tracks.concat(root.activeSequenceData.audio_tracks);

                                                    for (let tIdx = 0; tIdx < allTracks.length; tIdx++) {
                                                        let trk = allTracks[tIdx];
                                                        for (let cIdx = 0; cIdx < trk.clips.length; cIdx++) {
                                                            let c = trk.clips[cIdx];
                                                            // Sync all clips that originated from the same asset
                                                            if (c.item.asset_id === modelData.item.asset_id) {
                                                                let destTrack = (c.id === modelData.id) ? droppedTrackIdx : tIdx;
                                                                let oldStartTick = c.start_time ? c.start_time.value : 0;
                                                                let newStartTick = Math.max(0, oldStartTick + deltaTick);

                                                                targetCmds.push({
                                                                    type: "MoveClipInSequence",
                                                                    payload: {
                                                                        sequence_id: root.activeSequenceId,
                                                                        clip_id: c.id,
                                                                        new_track_index: destTrack,
                                                                        new_start_time: { value: newStartTick, rate: 30 }
                                                                    }
                                                                });
                                                            }
                                                        }
                                                    }

                                                    // Snap back visually immediately so QML constraints don't break
                                                    clipRect.x = startRectX;
                                                    clipRect.y = startRectY;

                                                    // Delay slightly more to ensure MouseArea cleans up internal C++ pointers
                                                    dispatchTimer.interval = 50;
                                                    for (let cmd of targetCmds) {
                                                        dispatchTimer.queueCommand(JSON.stringify(cmd));
                                                    }
                                                }
                                            }
                                        }

                                        // ── Left Trim Handle ──
                                        Rectangle {
                                            id: leftTrimHandle
                                            x: 0; y: 0
                                            width: 8; height: parent.height
                                            radius: 3
                                            color: leftTrimHover.containsMouse ? "#99ffffff" : "#33ffffff"
                                            z: 15
                                            HoverHandler { id: leftTrimHover }
                                            property real trimStartX: 0
                                            property real trimOrigStartSecs: 0
                                            property real trimOrigDurSecs: 0
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.SizeHorCursor
                                                property real pressSceneX: 0
                                                onPressed: (mouse) => {
                                                    root.forceActiveFocus();
                                                    root.selectedClipId = modelData.id;
                                                    pressSceneX = mapToItem(null, mouse.x, 0).x;
                                                    leftTrimHandle.trimOrigStartSecs = clipRect.startSecs;
                                                    leftTrimHandle.trimOrigDurSecs   = clipRect.durationSecs;
                                                }
                                                onPositionChanged: (mouse) => {
                                                    if (!pressed) return;
                                                    let curSceneX = mapToItem(null, mouse.x, 0).x;
                                                    let deltaSecs = (curSceneX - pressSceneX) / root.timeScale;
                                                    let newStartSecs = Math.max(0, leftTrimHandle.trimOrigStartSecs + deltaSecs);
                                                    let newDurSecs   = Math.max(0.1, leftTrimHandle.trimOrigDurSecs - (newStartSecs - leftTrimHandle.trimOrigStartSecs));
                                                    clipRect.x     = newStartSecs * root.timeScale;
                                                    clipRect.width = Math.max(8, newDurSecs * root.timeScale);
                                                }
                                                onReleased: {
                                                    let newStartSecs = clipRect.x / root.timeScale;
                                                    let newDurSecs   = clipRect.width / root.timeScale;
                                                    let newStartTick = Math.max(0, Math.floor(newStartSecs * 30));
                                                    let newDurTick   = Math.max(1, Math.floor(newDurSecs * 30));
                                                    // Reset visual to data-driven layout; backend will re-render
                                                    clipRect.x     = clipRect.startSecs * root.timeScale;
                                                    clipRect.width = Qt.binding(() => Math.max(1, clipRect.durationSecs * root.timeScale));
                                                    // We re-add with new timing by remove + add. MVP shortcut.
                                                    // TODO: Add a dedicated TrimClip command for in/out point editing.
                                                    console.log("Trim-in: newStart=", newStartTick, "newDur=", newDurTick);
                                                }
                                            }
                                        }

                                        // ── Right Trim Handle ──
                                        Rectangle {
                                            id: rightTrimHandle
                                            anchors.right: parent.right
                                            y: 0
                                            width: 8; height: parent.height
                                            radius: 3
                                            color: rightTrimHover.containsMouse ? "#99ffffff" : "#33ffffff"
                                            z: 15
                                            HoverHandler { id: rightTrimHover }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.SizeHorCursor
                                                property real pressSceneX: 0
                                                property real origWidth: 0
                                                onPressed: (mouse) => {
                                                    root.forceActiveFocus();
                                                    root.selectedClipId = modelData.id;
                                                    pressSceneX = mapToItem(null, mouse.x, 0).x;
                                                    origWidth = clipRect.width;
                                                }
                                                onPositionChanged: (mouse) => {
                                                    if (!pressed) return;
                                                    let curSceneX = mapToItem(null, mouse.x, 0).x;
                                                    let delta = curSceneX - pressSceneX;
                                                    clipRect.width = Math.max(8, origWidth + delta);
                                                }
                                                onReleased: {
                                                    let newDurSecs  = clipRect.width / root.timeScale;
                                                    let newDurTick  = Math.max(1, Math.floor(newDurSecs * 30));
                                                    // Reset: TODO proper TrimClip command
                                                    clipRect.width = Qt.binding(() => Math.max(1, clipRect.durationSecs * root.timeScale));
                                                    console.log("Trim-out: newDur=", newDurTick);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                
                // Interactive Playhead (spans ruler and tracks)
                Rectangle {
                    id: playhead
                    // currentTimeMs converted to seconds * timeScale
                    x: root.trackHeaderWidth + ((root.visualTimeMs / 1000) * root.timeScale)
                    y: 48 // Start at the top of the ruler (below 28px toolbar + 20px name bar)
                    width: 2
                    height: parent.height - 48
                    color: "#ff3333"
                    z: 100 // Above tracks
                    
                    // The triangle cap at the top (in the ruler)
                    Canvas {
                        width: 13
                        height: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = "#ff3333";
                            ctx.beginPath();
                            ctx.moveTo(0, 0);
                            ctx.lineTo(width, 0);
                            ctx.lineTo(width, height - 5);
                            ctx.lineTo(width/2, height);
                            ctx.lineTo(0, height - 5);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }
}
