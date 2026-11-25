pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Widgets


import "../../../components"
import "../../../config"
import "../../../services"


StyledText {
    id: root
    color: Config.appearance.color_fg
    required property var model

    property bool scroll_latch: false
    property int scroll_latch_duration: widget_config?.scroll_delay ?? 0
    property int value: Math.round((Brightnessctl.bri/Brightnessctl.bri_max)*root.value_max)
    property real wheel_acc: 0
    property int value_max: 5000;

    text: Brightnessctl.get_icon()

    /*
    Connections {
        target: Brightnessctl

        function onBrightnessChanged(brightness: int, icon: string) {
            root.text = icon
            root.value = Math.round((root.value_max/100)*brightness);
        }
    }
    */

    Timer {
        id: tmr_commit
        interval: 25 // Commit changes every 25ms to avoid skipping
        running: false
        repeat: false
        onTriggered: {
            const steps = Math.trunc(root.wheel_acc)
            if( steps == 0 ) return
            root.wheel_acc -= steps

            Brightnessctl.set(Math.max(0, Math.min(Brightnessctl.bri_max, Brightnessctl.bri + steps)))
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: (mouse)=> {
            const actionl = root.model?.config?.on_click ?? ""
            const actionr = root.model?.config?.on_click_right ?? ""
            const actionm = root.model?.config?.on_click_middle ?? ""

            switch( mouse.button ) {
                case Qt.RightButton:
                    if( actionr == "" ) return;
                    console.info("brightness->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) {
                        Brightnessctl.toggle();
                        return;
                    }
                    console.info("brightness->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("brightness->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }
        }

        onWheel: (wheel)=> {
            if( wheel.angleDelta.y == 0 ) return;
            let dir = "";

            if( wheel.angleDelta.y < 0 ) { // scroll up
                dir = "UP"
            } else { // scroll down
                dir = "DOWN"
            }

            // Same problems as Volume.qml - since I'm lazy and just copied it :)
            root.wheel_acc -= wheel.angleDelta.y * (Brightnessctl.bri_max / root.value_max)
            if( root.widget_debug ) console.debug("backlight->onWheel() " + wheel.angleDelta + " -> acc " + root.wheel_acc)
            tmr_commit.running = true
        }

        StyledTooltip {
            anchorItem: ma
            text: "<strong>" + Math.round((Brightnessctl.bri/Brightnessctl.bri_max)*100) + "%</strong>"
        }
    }
}

