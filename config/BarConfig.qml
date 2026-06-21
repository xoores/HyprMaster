import Quickshell.Io
import QtQuick
import QtQml.Models

JsonObject {
    id: root
    property bool persistent: true

    property ListModel widgets_left: ListModel { objectName: "widgets_left" }
    property ListModel widgets_center: ListModel { objectName: "widgets_center" }
    property ListModel widgets_right: ListModel { objectName: "widgets_right" }


    function _parse_widgets(widgets_config, widgets): void {
        if( widgets_config === undefined ) return;

        widgets.clear()

        console.debug("Parsing widgets: " + widgets.objectName)

        let x = 0
        for ( const w of widgets_config ) {
            if( w.type === undefined ) {
                console.error("Config error: config." + widgets.objectName + " contains widget of undefined type!")
                continue
            }

            console.debug("" + widgets.objectName + "[" + x + "]: " + w.type)

            switch( w.type ) {
                case "battery":     // Simple battery indicator
                case "bluetooth":   // Bluetooth indicator w/ toggles
                case "backlight_ext": // Brightness indicator (using external commands)
                case "backlight":   // Brightness indicator (using brightnessctl)
                case "datetime":    // Datetime indicator
                case "exec":        // Universal runner, shows script output
                case "inhibitor":   // Idle inhibitor
                case "volume":      // Volume indicator (using Pipewire connection)
                case "microphone":  // Microphone indicator (using Pipewire connection)
                case "volume_ext":  // Volume indicator (using external commands)
                case "workspaces":  // Hyprland workspaces list
                case "wifi":        // Wifi status w/ IP & SSID
                case "netif":       // Generic interface status (with IP)
                case "notifindicator": // Notification indicator/DND toggle
                case "inetmon":     // Internet connection / ICMP monitor
                case "tray": // ....
                    widgets.append({ type: w.type, config: w.config ?? {}  })
                    break;

                default:
                    console.error("Config error: config." + widgets.objectName + " contains widget of unsupported type '" + w.type + "'")
                    continue
            }

            x++
        }
    }

    function parse_config( cfg ) {
        if( !cfg ) return
        console.log(`CFG[BAR]: Loading`)

        for( const c in cfg ) {
            if( c === "#" ) continue

            console.log(`CFG[BAR]: '${c}' = '${cfg[c]}'`)
            _parse_widgets(cfg[c], root[c])
        }
    }
}
