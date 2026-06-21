pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "../config"
import "../services"

Variants {
    model: Quickshell.screens

    LazyLoader {
        required property var modelData
        active: root.isRecording && root._recordingScreen === modelData

        PanelWindow {
            id: recBadgeWindow
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            mask: Region {
                Region { item: recBadge }
            }

            // How many pixels we push out the pulsing border so it is out the way of the recording itself
            readonly property real margin: 4

            property real pulse: 1.0

            SequentialAnimation on pulse {
                loops: Animation.Infinite
                NumberAnimation { to: 0.5;  duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
            }

            Rectangle { // top border
                x: root._recordingLocalX - recBadgeWindow.margin
                y: root._recordingLocalY - recBadgeWindow.margin
                width: root._recordingW + recBadgeWindow.margin * 2
                height: 2
                color: Qt.rgba(1, 0.1, 0.1, recBadgeWindow.pulse)
            }
            Rectangle { // bottom border
                x: root._recordingLocalX - recBadgeWindow.margin
                y: root._recordingLocalY + root._recordingH + recBadgeWindow.margin - 2
                width: root._recordingW + recBadgeWindow.margin * 2
                height: 2
                color: Qt.rgba(1, 0.1, 0.1, recBadgeWindow.pulse)
            }
            Rectangle { // left border
                x: root._recordingLocalX - recBadgeWindow.margin
                y: root._recordingLocalY - recBadgeWindow.margin + 2
                width: 2
                height: root._recordingH + recBadgeWindow.margin * 2 - 4
                color: Qt.rgba(1, 0.1, 0.1, recBadgeWindow.pulse)
            }
            Rectangle { // right border
                x: root._recordingLocalX + root._recordingW + recBadgeWindow.margin - 2
                y: root._recordingLocalY - recBadgeWindow.margin + 2
                width: 2
                height: root._recordingH + recBadgeWindow.margin * 2 - 4
                color: Qt.rgba(1, 0.1, 0.1, recBadgeWindow.pulse)
            }

            Rectangle {
                id: recBadge
                x: root._recordingLocalX - recBadgeWindow.margin
                y: root._recordingLocalY - recBadgeWindow.margin - height - 4
                width: badgeLabel.implicitWidth + 16
                height: 24
                radius: 4
                color: isHovered ? Qt.rgba(0.7, 0, 0, 1.0) : Qt.rgba(1.0, 0, 0, recBadgeWindow.pulse)

                property bool isHovered: false

                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: recBadge.isHovered ? "  Stop" : "󰑋  Recording"
                    color: Config.appearance.color_fg
                    font.pixelSize: Config.appearance.font_size
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: recBadge.isHovered = true
                    onExited:  recBadge.isHovered = false
                    onClicked: root.stopRecording()
                }
            }
        }
    }
}