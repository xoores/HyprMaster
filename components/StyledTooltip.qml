pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "../config"
import "../services"


LazyLoader {
    id: root

    required property Item anchorItem
    property var anchorWindow: anchorItem.QsWindow.window
    property bool show: anchorItem.containsMouse
    required property string text

    property color backgroundColor: "black"
    property color textColor: "white"
    property int showDelay: 300
    property int hideDuration: 200
    property int autoCloseTimeout: 30000
    property bool keepAlive: false
    active: show || keepAlive

    onShowChanged: {
        if (show) {
            keepAlive = true
        } else if (item) {
            item.beginClose()
        } else {
            keepAlive = false
        }
    }

    PopupWindow {
        id: popup

        property bool reveal: false

        function beginClose() {
            showDelayTimer.stop()
            autoCloseTimer.stop()
            closeTimer.restart()
            reveal = false
        }

        visible: reveal || closeTimer.running
        color: "transparent"
        implicitWidth: tooltipText.implicitWidth + 10
        implicitHeight: tooltipText.implicitHeight + 10


        anchor.window: root.anchorWindow
        anchor.rect: root.anchorWindow
                        ? Qt.rect(Math.round(root.anchorItem.QsWindow.itemPosition(root.anchorItem).x), Math.round(root.anchorWindow.height), root.anchorItem.width, 0)
                        : Qt.rect(0, 0, 0, 0)

        Rectangle {
            id: content
            anchors.fill: parent
            anchors.margins: 1
            color: Config.appearance.color_primary_active
            border.color: Config.appearance.color_accent_active
            border.width: 1
            radius: Config.appearance.radius / 4
            opacity: popup.reveal ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: root.hideDuration; easing.type: Easing.InOutQuad }
            }

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: root.text
                color: Config.appearance.color_fg
                font.family: Config.appearance.font_family
                font.pixelSize: Config.appearance.font_size
            }
        }

        Timer {
            id: showDelayTimer
            interval: root.showDelay
            running: true
            onTriggered: popup.reveal = true
        }

        Timer {
            id: autoCloseTimer
            interval: root.autoCloseTimeout
            running: true
            onTriggered: popup.beginClose()
        }

        Timer {
            id: closeTimer
            interval: root.hideDuration
            onTriggered: root.keepAlive = false
        }
    }
}