pragma ComponentBehavior: Bound

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

    text: Pw.get_icon()
    color: Pw.muted ? Config.appearance.color_fg_disabled : Config.appearance.color_fg_active

    //property int value: Math.round((value_max/Pw.volume_max)*Pw.volume);
    property int value_max: 5000;
    property string sink_name: (Pw.sink?.nickname || Pw.sink?.description || Pw.sink?.name || "?")
    property real wheel_acc: 0

    Behavior on color {
        CAnim { }
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
                    console.info("pw->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) {
                        Pw.toggle();
                        return;
                    }
                    console.info("pw->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("pw->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }
        }

        onWheel: (wheel)=> {
            if (wheel.angleDelta.y == 0) return;

            root.wheel_acc -= wheel.angleDelta.y
            const unit = root.value_max / Pw.volume_max
            const steps = Math.trunc(root.wheel_acc / unit)

            if (steps == 0) return;
            root.wheel_acc -= steps * unit

            Pw.set(Math.max(0, Math.min(Pw.volume_max, Pw.volume + steps)))

            if( root.widget_debug ) console.debug("pw->onWheel() " + wheel.angleDelta)
        }


        StyledTooltip {
            anchorItem: ma
            text: "<strong>" + root.sink_name + ": " + Pw.volume + "%</strong>" + (Pw.muted ? "<br>MUTED" : "")
        }
    }
}

