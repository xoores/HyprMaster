pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../config"
import "../services"

PanelWindow {
    id: overlay

    required property var   targetScreen
    property bool           doFreeze: true         // Screen freeze when taking a screenshot
    property bool           actionRecording: false // Used only for selecting proper words on screen

    // 3 different events we emit:
    // regionSelected -> user has manually selected some region (either click-and-drag or a window)
    // outputSelected -> usesr has selected whole screen
    // cancelled -> Self explainatory
    signal regionSelected(real globalX, real globalY, real w, real h, var screen, real localX, real localY)
    signal outputSelected(string screenName)
    signal cancelled()

    screen: targetScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    // We have to bootstrap from some existing element - when I used Screen.virtualX/Y directly, it
    // did not work because those values got assigned *before* the Screen has been actually assigned
    // to its proper place and all of them had the same value... FML
    readonly property real  vOriginX: frozenBg.Screen.virtualX
    readonly property real  vOriginY: frozenBg.Screen.virtualY
    property var            hoveredClient: null
    property bool           isDragging: false
    property bool           hasDragResult: false  // true once a drag finishes
    property string         hyprlandMonitorName: "" // For logging purposes
    property bool           freezeReady: false

    onHoveredClientChanged:             dimCanvas.requestPaint()
    onIsDraggingChanged:                dimCanvas.requestPaint()
    onHasDragResultChanged:             dimCanvas.requestPaint()
    onHoveredClientLocalRectChanged:    dimCanvas.requestPaint()
    Component.onCompleted: {
        focusSink.forceActiveFocus()
        if( !doFreeze ) dimCanvas.requestPaint() // No freeze = ready immediately
    }

    property list<var>  clients: {
        const mon = Hypr.monitorFor(screen);
        if( !mon ) {
            hyprlandMonitorName = "??"
            return [];
        }

        hyprlandMonitorName = mon.name

        const special = mon.lastIpcObject.specialWorkspace;
        const wsId = special.name ? special.id : mon.activeWorkspace.id;

        return Hypr.toplevels.values.filter(c => c.workspace?.id === wsId).sort((a, b) => {
                // Pinned first, then fullscreen, then floating, then any other
                const ac = a.lastIpcObject;
                const bc = b.lastIpcObject;
                return (bc.pinned - ac.pinned) ||
                        ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) ||
                        (bc.floating - ac.floating);
            });
    }

    function findClientAt(localX, localY) {
        //console.log(`[${hyprlandMonitorName}]: vOrigin=${vOriginX},${vOriginY}  local=${Math.round(localX)},${Math.round(localY)}`)

        const gx = vOriginX + localX
        const gy = vOriginY + localY

        //console.log(`[${hyprlandMonitorName}|${Math.round(gx)},${Math.round(gy)}]: ${clients.length} clients`)
        for (const c of clients) {
            if( !c ) continue;

            let {
                at: [cx, cy],
                size: [cw, ch]
            } = c.lastIpcObject;
            //console.log(`[${hyprlandMonitorName}]:   |- ${c.title}  ${cx},${cy}:${cw}x${ch}`)

            if( cx <= gx && cy <= gy && cx + cw >= gx && cy + ch >= gy ) {
                sel.startX = cx - screen.x
                sel.startY = cy - screen.y
                sel.w = cw
                sel.h = ch
                //console.log(`[${hyprlandMonitorName}]: SELECTED CLIENT ${c.title}  ${cx},${cy}:${cw}x${ch}`)
                return c;
            }
        }
        //console.log(`[${hyprlandMonitorName}]: NO VALID CLIENT`)
        return null
    }

    readonly property rect hoveredClientLocalRect: {
        if( !hoveredClient ) return Qt.rect(0, 0, 0, 0)

        let {
            at: [cx, cy],
            size: [cw, ch]
        } = hoveredClient.lastIpcObject;

        return Qt.rect( cx - vOriginX, cy - vOriginY, cw, ch )
    }

    // Background freeze
    Loader {
        id: screencopyLoader
        active: overlay.doFreeze
        sourceComponent: Component {
            ScreencopyView {
                width:  overlay.width
                height: overlay.height
                captureSource: overlay.targetScreen
                visible: !overlay.freezeReady
            }
        }
    }

    Image {
        id: frozenBg
        anchors.fill: parent
        visible: overlay.doFreeze && overlay.freezeReady
        cache: false
        z: 0
    }

    // Wait a little before grabbing a freeze frame so there are no artifacts...
    Timer {
        interval: 50
        running: overlay.doFreeze
        repeat: false
        onTriggered: {
            if( !screencopyLoader.item ) return
            screencopyLoader.item.grabToImage(function(result) {
                frozenBg.source = result.url
                overlay.freezeReady = true
                dimCanvas.requestPaint()
            })
        }
    }

    QtObject {
        id: sel
        property real startX: 0; property real startY: 0
        property real w: 0;      property real h: 0

        readonly property real normX: w >= 0 ? startX : startX + w
        readonly property real normY: h >= 0 ? startY : startY + h
        readonly property real normW: Math.abs(w)
        readonly property real normH: Math.abs(h)
        readonly property bool hasSelection: normW > 4 && normH > 4
    }

    // Dimming layer
    Canvas {
        id: dimCanvas
        anchors.fill: parent
        z: 1

        readonly property bool readyToPaint: !overlay.doFreeze || overlay.freezeReady

        onReadyToPaintChanged: if( readyToPaint ) requestPaint()

        onPaint: {
            if( !readyToPaint ) return
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = Config.appearance.color_primary_active.replace("#", "#aa")
            ctx.fillRect(0, 0, width, height)

            let r = Qt.rect(0, 0, 0, 0)
            let isWindowHover = false

            if( overlay.isDragging && sel.hasSelection ) {
                r = Qt.rect(sel.normX, sel.normY, sel.normW, sel.normH)
            } else if( overlay.hasDragResult && sel.hasSelection ) {
                r = Qt.rect(sel.normX, sel.normY, sel.normW, sel.normH)
            } else if( overlay.hoveredClient ) {
                r = overlay.hoveredClientLocalRect
                isWindowHover = true
            }

            if( r.width > 4 && r.height > 4 ) {
                ctx.clearRect(r.x, r.y, r.width, r.height)
                ctx.strokeStyle = Config.appearance.color_fg
                ctx.lineWidth = 1
                ctx.strokeRect(r.x + 1, r.y + 1, r.width - 2, r.height - 2)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        hoverEnabled: !overlay.hasDragResult && !overlay.isDragging
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: (overlay.isDragging || overlay.hasDragResult)
            ? Qt.CrossCursor
            : (overlay.hoveredClient ? Qt.PointingHandCursor : Qt.CrossCursor)

        onExited: {
            if (!overlay.isDragging) overlay.hoveredClient = null
        }

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                overlay.cancelled()
                return
            }
            sel.startX = mouse.x
            sel.startY = mouse.y
            sel.w = 0
            sel.h = 0
            overlay.isDragging    = false
            overlay.hasDragResult = false
            overlay.hoveredClient = null
        }

        onPositionChanged: (mouse) => {
            if (mouse.buttons & Qt.LeftButton) {
                const dx = mouse.x - sel.startX
                const dy = mouse.y - sel.startY
                if (!overlay.isDragging && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) {
                    overlay.isDragging    = true
                    overlay.hasDragResult = false
                    overlay.hoveredClient = null
                }
                if (overlay.isDragging) {
                    // Limit selection to one screen
                    const ex = Math.max(0, Math.min(mouse.x, overlay.width))
                    const ey = Math.max(0, Math.min(mouse.y, overlay.height))
                    sel.w = ex - sel.startX
                    sel.h = ey - sel.startY
                    dimCanvas.requestPaint()
                }
            } else if (!overlay.hasDragResult) {
                overlay.hoveredClient = overlay.findClientAt(mouse.x, mouse.y)
            }
        }

        onReleased: (mouse) => {
            if (mouse.button === Qt.RightButton) return
            if (overlay.isDragging) {
                overlay.isDragging    = false
                overlay.hasDragResult = true
                dimCanvas.requestPaint()
            } else if (overlay.hoveredClient) {
                const c = overlay.hoveredClient
                overlay.regionSelected(
                    c.at.x, c.at.y, c.size.width, c.size.height,
                    overlay.targetScreen,
                    c.at.x - overlay.vOriginX,
                    c.at.y - overlay.vOriginY
                )
            }
        }
    }

    Item {
        id: focusSink
        anchors.fill: parent
        z: 3
        focus: true

        Keys.onReturnPressed: confirmCapture()
        Keys.onEnterPressed:  confirmCapture() // numpad enter too!
        Keys.onEscapePressed: overlay.cancelled()

        function confirmCapture() {
            if( !sel.hasSelection ) return;

            dimRectangle.visible = false
            hudRectangle.visible = false


            // callLater is necessary because we need to give a little bit of time to dimRectangle and hudRectangle
            // to disappear. If we emit the signal without that, both rectangles would be in the creenshot.
            Qt.callLater(() => {
                    overlay.regionSelected(
                     overlay.vOriginX + sel.normX,
                     overlay.vOriginY + sel.normY,
                     sel.normW, sel.normH,
                     overlay.targetScreen,
                     sel.normX, sel.normY)
                    })

        }
    }

    // Label: dimenstions
    Rectangle {
        id: dimRectangle
        z: 4
        visible: sel.hasSelection
        x: Math.max(4, Math.min(sel.normX + sel.normW / 2 - width  / 2, overlay.width  - width  - 4))
        y: Math.max(4, Math.min(sel.normY + sel.normH + 8, overlay.height - height - 4))
        width:  dimLabel.implicitWidth  + 12
        height: dimLabel.implicitHeight + 6
        color: Config.appearance.color_bg_dark
        radius: Config.appearance.radius / 4

        Text {
            id: dimLabel
            anchors.centerIn: parent
            color: Config.appearance.color_fg
            font.pixelSize: Config.appearance.font_size
            text: `${Math.round(sel.normW)} x ${Math.round(sel.normH)}`
        }
    }

    // Label: instructions
    Rectangle {
        id: hudRectangle
        z: 4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 2
        width: hudLabel.implicitWidth + 24
        height: hudLabel.implicitHeight + 12
        color: Config.appearance.color_bg_dark
        radius: Config.appearance.radius / 4

        Text {
            id: hudLabel
            anchors.centerIn: parent
            color: Config.appearance.color_fg
            font.pixelSize: Config.appearance.font_size
            text: {
                const verb = overlay.actionRecording ? "start recording" : "grab"
                if( overlay.isDragging )
                    return `Release to set selection  ~  Right-click to cancel`
                if( overlay.hasDragResult && sel.hasSelection )
                    return `Enter to ${verb}  ~  Drag to reselect  ~  Esc / Right-click to cancel`
                if( overlay.hoveredClient )
                    return `Enter to ${verb} window  ~  Drag for custom area  ~  Esc / Right-click to cancel`
                return `Hover over a window or drag to select area  ~  Esc / Right-click to cancel`
            }
        }
    }

}