pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import "../../../components"
import "../../../config"
import "../../../services"


StyledText {
    id: root
    required property var model

    property bool scroll_latch: false
    property int scroll_latch_duration: widget_config?.scroll_delay ?? 0

    text: Pw.get_mic_icon()
    color: Pw.get_mic_color()

    property int value: Math.round((value_max/Pw.volume_max)*Pw.volume);
    property int value_max: 5000;

    SequentialAnimation on color {
        running: Pw.mic_in_use && Pw.mic_muted === false
        loops: Animation.Infinite
        alwaysRunToEnd: true
        ColorAnimation { to: Config.appearance.color_fg_error; duration: 700 }
        ColorAnimation { to: Config.appearance.color_fg; duration: 700 }
    }


    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse)=> {
            const actionl = root.model?.config?.on_click ?? ""
            const actionr = root.model?.config?.on_click_right ?? ""
            const actionm = root.model?.config?.on_click_middle ?? ""

            switch( mouse.button ) {
                case Qt.RightButton:
                    if( actionr == "" ) return;
                    console.info("micro->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) {
                        Pw.micToggle();
                        return;
                    }
                    console.info("micro->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("micro->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }
        }


        StyledTooltip {
            anchorItem: ma
            text: Pw.mic_muted ? "Microphone muted" : "Microphone unmuted"
        }
        /*
        onWheel: (wheel)=> {
            if( wheel.angleDelta.y == 0 ) return;

            root.value -= wheel.angleDelta.y // -= because we want numbers to go up when scrolling up...
            if( root.value > root.value_max ) root.value = root.value_max // Cap max
            if( root.value < 0 ) root.value = 0 // Limit min
            const vol_value = Math.round(root.value * (Pw.volume_max/root.value_max)) // Fit to the Brightnessctl range (0-X)
            Pw.set(vol_value)

            if( root.widget_debug ) console.debug("micro->onWheel(" + dir + ") " + wheel.angleDelta)
        }
        */
    }
}

