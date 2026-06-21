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

    property int master_volume: -1

    property bool master_mute: false
    property bool scroll_latch: false
    property int scroll_latch_duration: widget_config?.scroll_delay ?? 0

    text: ""

    function get_icon(): string {
        const icons = ["", "", ""];

        // No matter how many icons we have, if we are >80% we report the "max"
        if( master_volume < 0 || master_volume >= 80 ) return icons[icons.length-1];

        const icon_id = Math.floor((master_volume/100)*(icons.length-1))

        //console.debug("volume=" + master_volume + "  icon_id=" + icon_id)
        return icons[icon_id];
    }

    function scroll_if_not_latched( command ): void {
        if( scroll_latch ) return;
        if( scroll_latch_duration > 0 ) {
            scroll_latch = true
            if( widget_debug ) console.debug("volume -> RUN, latching for " + scroll_latch_duration + "ms")
        }
        Quickshell.execDetached(command);

        if( scroll_latch_duration > 0 ) tmr.running = true

        tmr_refresh.running = true
    }


    Process {
        id: mute_refresh
        running: true
        command: ["sh", "-c", "pactl -f json get-sink-mute @DEFAULT_SINK@"] // To avoid warnings if asdbctl is not installed
        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( stdout.length == 0 ) return;

                try {
                    const mute = JSON.parse(stdout);
                    root.master_mute = mute.mute
                    if( mute.mute ) {
                        root.text = ""
                        root.color = Config.appearance.color_fg_disabled
                    } else {
                        root.color = Config.appearance.color_fg_active
                    }
                } catch (e) {
                    console.error("Volume: Failed to parse ip output:", e)
                }


                volume_refresh.running = true
            }
        }
    }

    // volume_refresh is started automatically after the mute_refresh finishes
    Process {
        id: volume_refresh
        running: false
        command: ["sh", "-c", "pactl -f json get-sink-volume @DEFAULT_SINK@ | jq -r '.volume.\"front-left\".value_percent'"] // To avoid warnings if asdbctl is not installed
        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( stdout.length == 0 ) return;

                const perc = stdout.slice(0,-1)
                root.master_volume = perc;

                if( root.master_mute === false ) {
                    root.text = root.get_icon();
                }
            }
        }
    }

    Timer {
        id: tmr
        interval: root.scroll_latch_duration
        running: false
        repeat: false
        onTriggered: root.scroll_latch = false
    }

    // For some reason the pactl will report mute=false even if it muted - have to wait
    // for a little while before that command I guess?
    Timer {
        id: tmr_refresh
        interval: 40
        running: false
        repeat: false
        onTriggered: mute_refresh.running = true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse)=> {
            const actionl = root.model?.config?.on_click ?? ""
            const actionr = root.model?.config?.on_click_right ?? ""
            const actionm = root.model?.config?.on_click_middle ?? ""

            switch( mouse.button ) {
                case Qt.RightButton:
                    if( actionr == "" ) return;
                    console.info("volume->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) return;
                    console.info("volume->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("volume->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }

            tmr_refresh.running = true

        }

        onWheel: (wheel)=> {
            if( wheel.angleDelta.y == 0 ) return;
            let dir = "";
            const actionup = root.model?.config?.on_scroll_up ?? ""
            const actiondown = root.model?.config?.on_scroll_down ?? ""

            if( wheel.angleDelta.y < 0 ) { // scroll up
                dir = "UP"
                if( actionup == "" ) return;
                root.scroll_if_not_latched(actionup);
            } else { // scroll down
                dir = "DOWN"
                if( actiondown == "" ) return;
                root.scroll_if_not_latched(actiondown);

            }
            if( root.widget_debug ) console.debug("vol->onWheel(" + dir + ") " + wheel.angleDelta)

        }
    }
}

