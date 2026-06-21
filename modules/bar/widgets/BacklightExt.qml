pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import qs.components


StyledText {
    id: root
    color: Config.appearance.color_fg
    required property var model

    property int monitor_brightness: -1
    property bool scroll_latch: false
    property int scroll_latch_duration: widget_config?.scroll_delay ?? 0

    text: "󱩑"

    function get_icon(): string {
        const icons = ["󱩍", "󱩎", "󱩏", "󱩐", "󱩑", "󱩒", "󱩓", "󱩔", "󱩕", "󱩖", "󰛨"];
        if( monitor_brightness < 0 || monitor_brightness >= 85 ) return icons[icons.length-1];

        const icon_id = Math.floor(monitor_brightness/icons.length) % icons.length;

        console.debug("monitor_brightness=" + monitor_brightness + "  icon_id=" + icon_id)
        return icons[icon_id];
    }

    function scroll_if_not_latched( command ): void {
        if( scroll_latch ) return;
        if( scroll_latch_duration > 0 ) {
            scroll_latch = true
            if( widget_debug ) console.debug("RUN -> latching for " + scroll_latch_duration + "ms")
        }
        Quickshell.execDetached(command);

        if( scroll_latch_duration > 0 ) tmr.running = true

        brightness_refresh.running = true
    }

    Process {
        id: brightness_refresh
        running: true
        command: ["sh", "-c", "brightnessctl -m i"] // To avoid warnings if asdbctl is not installed
        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( stdout.length == 0 ) return;

                let data = stdout.split(",");
                let perc = data[3].split("%")[0];

                console.debug(data + " -> data[3]=" + perc)
                root.monitor_brightness = perc; //Math.round(data[4]/data[2])
                root.text = root.get_icon();
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
                    console.info("brightness->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) return;
                    console.info("brightness->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("brightness->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }

            brightness_refresh.running = true

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
            if( root.widget_debug ) console.debug("bt->onWheel(" + dir + ") " + wheel.angleDelta)

        }
    }
}

