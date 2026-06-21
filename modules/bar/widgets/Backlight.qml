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
            const bri_value = Math.round(root.value * (Brightnessctl.bri_max/root.value_max)) // Fit to the Brightnessctl range (0-X)

            Brightnessctl.set(bri_value)
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


            root.value -= wheel.angleDelta.y // -= because we want numbers to go up when scrolling up...
            if( root.value > root.value_max ) root.value = root.value_max // Cap max
            if( root.value < 0 ) root.value = 0 // Limit min
            if( root.widget_debug ) console.debug("bt->onWheel(" + dir + ") " + wheel.angleDelta + " -> " + root.value)
            tmr_commit.running = true

        }

        StyledTooltip {
            anchorItem: ma
            text: "<strong>" + Math.round((Brightnessctl.bri/Brightnessctl.bri_max)*100) + "%</strong>"
        }
    }
}

