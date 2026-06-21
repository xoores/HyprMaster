pragma Singleton
pragma ComponentBehavior: Bound

//import "../config"

import Quickshell
import Quickshell.Io
import QtQuick

import "../config"


Singleton
{
    id: root
    reloadableId: "backlight"
    property int bri: -1
    property int bri_max: -1
    readonly property int change_step: bri <= 50 ? 1 : 20

    property int latch: 0;
    property int latch_value: 2;

    // Normalized value of brightness in % (0-100)
    signal brightnessChanged(brightness: int, icon: string);

    function get_icon(): string {
        const icons = ["󱩍", "󱩎", "󱩏", "󱩐", "󱩑", "󱩒", "󱩓", "󱩔", "󱩕", "󱩖", "󰛨"];

        if( root.bri < 0 || root.bri >= (root.bri_max*0.85) ) return icons[icons.length-1];

        const icon_id = Math.floor(root.bri*(icons.length/root.bri_max));

        //console.debug("monitor_brightness=" + root.brightness + "  icon_id=" + icon_id + "/" + x)
        return icons[icon_id];
    }

    function set_perc( perc: int ) {
        if( perc < 0 || perc > 100 ) {
            console.error("BacklightSvc: set_perc(" + perc + ") failed, invalid value")
            return;
        }

        set( Math.round( (root.bri_max/100) * perc) )

    }

    function set(level: int): void {

        if( level < 0 || level > bri_max ) {
            console.error("BacklightSvc: set(" + level + ") failed, invalid value")
            return;
        }

        // Emit event only if we have a real change
        if( level == root.bri ) return

        //console.debug("BacklightSvc: set(" + level + ")")
        root.bri = level;
        root.brightnessChanged( (level/root.bri_max)*100, root.get_icon())
        brightness_set.running = true
    }

    function toggle(): void {
        let target = root.bri > 3 ? 3 : root.bri_max
        set(target)
    }

    function increase(): void {
        let target = root.bri + root.change_step
        if( target > root.bri_max ) target=root.bri_max;
        set(target)
    }

    function decrease(): void {
        let target = root.bri - root.change_step
        if( target < 3 ) target=3;
        set(target)
    }


    function parse_brightnessctl_output( text: string ): void {
        let stdout = text.trim()
        if( stdout.length == 0 ) return;

        const [, , curr_raw, curr_perc, max_raw]  = stdout.split(",");
        let perc = curr_perc.split("%")[0];
        root.bri_max = max_raw
        //root.bri = curr_raw

        //console.debug(">>>" + stdout + " -> curr_perc=" + perc)

        root.set(curr_raw);

        tmr_refresh.running = false
        tmr_refresh.running = true
    }

    // Refresh every 15s - not *really* necessary, but handy if something else changes
    // brightness. We will get in sync eventually.
    Timer {
        id: tmr_refresh
        interval: 15000
        running: true
        repeat: true
        onTriggered: brightness_get.running = true
    }

    Process {
        id: brightness_get
        running: true
        command: ["brightnessctl", "-m", "i"]
        stdout: StdioCollector {
            onStreamFinished: { root.parse_brightnessctl_output(text) }
        }
    }

    Process {
        id: brightness_set
        running: false
        command: ["brightnessctl", "-m", "s", root.bri]
        stdout: StdioCollector {
            onStreamFinished: { root.parse_brightnessctl_output(text) }
        }
    }

    IpcHandler {
        target: "brightness"
        function increase() { onPressed: root.increase() }
        function decrease() { onPressed: root.decrease() }
        function toggle() { onPressed: root.toggle() }
    }

}
