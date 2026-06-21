pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import Quickshell.Services.UPower
import "../../../components"
import "../../../config"

StyledText {
    id: root
    text: get_battery_text()


    color: {
        if( !UPower.onBattery ) return Config.appearance.color_fg_good;
        return UPower.displayDevice.percentage > 0.2 ? Config.appearance.color_fg_warning : Config.appearance.color_fg_error
    }

    // Redraw every 5s
    Timer {
        id: tmr
        interval: 5000; running: true; repeat: true
        onTriggered: root.text = root.get_battery_text()
    }

    // Redraw immediately on plug/unplug
    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            //tmr.interval = UPower.onBattery ? 5000 : 10000;
            root.text = root.get_battery_text()
        }
    }

    function get_battery_text(): string {
        if( !UPower.displayDevice.ready ) return "󰂑";

        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        const icons_charging = [ "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅" ]
        const perc = Math.round(UPower.displayDevice.percentage * 100);
        const icon_id = Math.floor(perc/icons.length) - 1
        // icon_id =- 1;
        //if( icon_id >= icons.length ) icon_id = icons.length-1;

        const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
        let icon = charging ? icons_charging[icon_id] : icons[icon_id]
        //console.debug("DeviceState=" + UPower.displayDevice.state + "  perc=" + perc + "  icon_id=" + icon_id + "  icon=" + icon )
        //console.debug(">>>" +icon_id)

        let timer = 0;
        if( charging ) {
            if (perc >= 99 || UPower.displayDevice.state == UPowerDeviceState.FullyCharged ) return "";
            timer = Math.floor(UPower.displayDevice.timeToFull / 60);
        } else {
            timer = Math.floor(UPower.displayDevice.timeToEmpty / 60);
        }

        if( timer > 0 ) {
            const timer_h = Math.floor(timer/60)
            const timer_m = (timer % 60).toString().padStart(2, '0')

            //console.debug("timer=" + timer + "  timer_h=" + timer_h + "  timer_m=" + timer_m )
            icon += " [" + timer_h + ":" + timer_m + "]"
        }

        return perc + "% " + icon;
    }


    /*
    Behavior on text {
        enabled: true

        SequentialAnimation {
            Anim {
                to: 0
                easing.bezierCurve: [0.3, 0, 1, 1, 1, 1]
            }
            PropertyAction {}
            Anim {
                to: 1
                easing.bezierCurve: [0, 0, 0, 1, 1, 1]
            }
        }
    }

    */
}

