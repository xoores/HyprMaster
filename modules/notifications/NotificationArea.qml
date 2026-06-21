pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Controls


import "../../config"
import "../../services"
import "../../components"

Singleton {
    id: root

    property int panelWidth: 380
    property bool windowOpen: false
    property var targetScreen: Quickshell.screens[0]

    function closeWindow() {
        if ( !loader.active ) return;

        if (loader.item) loader.item.requestClose();
    }

    function toggleWindow(screen) {
        if (loader.active) {
            closeWindow()
        } else {
            targetScreen = screen
            windowOpen = true
        }
    }

    LazyLoader {
        id: loader
        active: root.windowOpen

        PanelWindow {
            id: notifWindow

            screen: root.targetScreen
            focusable: true

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore


            function requestClose() {
                panel.slidIn = false
            }


            Item {
                id: focusScope
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: notifWindow.requestClose()

                Component.onCompleted: focusScope.forceActiveFocus()


                MouseArea {
                    anchors.fill: parent
                    onClicked: notifWindow.requestClose()
                }

                Rectangle {
                    id: panel

                    property bool slidIn: false

                    width: root.panelWidth

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: slidIn ? 0 : -width
                    anchors.topMargin: Config.appearance.bar_height

                    color: Config.appearance.color_bg

                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.InOutQuad
                            onRunningChanged: {
                                if (!running && !panel.slidIn) {
                                    root.windowOpen = false
                                }
                            }
                        }
                    }

                    Component.onCompleted: {
                        slidIn = true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {}
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 24

                            Text {
                                text: "Notifications"
                                color: Config.appearance.color_fg
                                font {
                                    family: Config.appearance.font_family
                                    pixelSize: Config.appearance.font_size
                                    bold: true
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "✕"
                                color: Config.appearance.color_fg
                                font {
                                    family: Config.appearance.font_family
                                    pixelSize: Config.appearance.font_size
                                    bold: true
                                }

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    onClicked: notifWindow.requestClose()
                                }
                            }
                        }


                        Flickable {
                            id: notificationFlick
                            width: parent.width
                            height: parent.height - 24 - parent.spacing
                            clip: true

                            contentWidth: width
                            contentHeight: listColumn.height
                            boundsBehavior: Flickable.StopAtBounds

                            // Tune these for the coasting feel
                            flickDeceleration: 600
                            maximumFlickVelocity: 5000
                            property real lastWheelTime: 0
                            property real lastVelocity: 0

                            property var wheelSamples: []

                            function pushWheelSample(dy) {
                                const now = Date.now()
                                wheelSamples.push({ t: now, dy: dy })
                                while (wheelSamples.length > 0 && now - wheelSamples[0].t > 60) {
                                    wheelSamples.shift()
                                }
                            }

                            function averageVelocity() {
                                if (wheelSamples.length < 2) return 0
                                const first = wheelSamples[0]
                                const last = wheelSamples[wheelSamples.length - 1]
                                const dt = (last.t - first.t) / 1000
                                if (dt <= 0) return 0
                                let totalDy = 0
                                for (const s of wheelSamples) totalDy += s.dy
                                return totalDy / dt
                            }

                            Column {
                                id: listColumn
                                width: notificationFlick.width
                                spacing: 8

                                Repeater {
                                    id: notificationRepeater
                                    // Yeah, could not figure any other "nice" way to reverse a list in QML without
                                    // doing something like this :-(
                                    model: [...Notifier.activeNotifications].reverse()

                                    delegate: Item {
                                        id: delegateWrapper

                                        required property var modelData

                                        // Height is driven by this property so we can animate it
                                        // independently of the NotificationItem's own implicit height.
                                        property real animatedHeight: notificationItem.height
                                        property bool dismissing: false

                                        width: notificationItem.width
                                        height: animatedHeight
                                        // Clip so the item disappears cleanly as height collapses
                                        clip: true

                                        function animateDismiss() {
                                            if (dismissing) return
                                            dismissing = true
                                            dismissAnimation.start()
                                        }

                                        SequentialAnimation {
                                            id: dismissAnimation

                                            // Phase 1: slide right off-screen + fade out
                                            ParallelAnimation {
                                                NumberAnimation {
                                                    target: notificationItem
                                                    property: "x"
                                                    to: notificationItem.width + 40
                                                    duration: 280
                                                    easing.type: Easing.InBack
                                                    easing.overshoot: 0.8
                                                }
                                                NumberAnimation {
                                                    target: notificationItem
                                                    property: "opacity"
                                                    to: 0
                                                    duration: 220
                                                    easing.type: Easing.InQuad
                                                }
                                            }

                                            // Phase 2: collapse height so notifications below
                                            // slide up smoothly to fill the gap
                                            NumberAnimation {
                                                target: delegateWrapper
                                                property: "animatedHeight"
                                                to: 0
                                                duration: 180
                                                easing.type: Easing.InOutQuad
                                            }

                                            // Dismiss only after the animation fully completes.
                                            // Qt.callLater defers past this handler so the delegate
                                            // is not torn down while still executing.
                                            onFinished: Qt.callLater(
                                                () => delegateWrapper.modelData.notification.dismiss()
                                            )
                                        }

                                        NotificationItem {
                                            id: notificationItem
                                            width: 350
                                            visibleProgress: false

                                            // Pass the Notif smart object (not modelData.notification
                                            // which is the raw Quickshell Notification and lacks
                                            // displayActions, timeStr and invokeAction)
                                            notification: delegateWrapper.modelData

                                            onDismissClicked: delegateWrapper.animateDismiss()
                                            onActionInvoked: index => delegateWrapper.modelData.invokeAction(index)
                                        }
                                    }
                                }
                            }

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                property real sensitivity: 1.8

                                onWheel: (event) => {
                                    let dy
                                    if (event.pixelDelta.y !== 0) {
                                        dy = event.pixelDelta.y * sensitivity
                                    } else {
                                        dy = (event.angleDelta.y / 120) * 40 * sensitivity
                                    }

                                    notificationFlick.contentY = notificationFlick.contentY - dy
                                    notificationFlick.pushWheelSample(dy)
                                    inertiaTimer.restart()
                                }
                            }

                            Timer {
                                id: inertiaTimer
                                interval: 24 // just past the typical gap between trackpad events, so handoff feels instant
                                onTriggered: {
                                    const v = notificationFlick.averageVelocity()
                                    if (Math.abs(v) > 50) {
                                        notificationFlick.flick(0, v)
                                    }
                                    notificationFlick.wheelSamples = []
                                }
                            }


                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }
                        }
                    }
                }
            }
        }
    }
}