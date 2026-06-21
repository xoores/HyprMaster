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
    color: Config.appearance.color_fg
    required property var model


    property int interval: widget_config?.interval ?? 5
    property string iface: widget_config?.iface ?? ""
    property string icon_up: widget_config?.icon_up ?? "U"
    property string icon_down: widget_config?.icon_down ?? "D"

    property string text_normal: ""
    property string text_extended: ""
    property bool mouse_hovering: false;

    // Yeah... This is one way to get all the information into one JSON alright
    readonly property string cmd_iw_link: "iw dev " + root.iface + " link"
    readonly property string cmd_ip_addr: "ip -j -4 addr show dev " + root.iface + " scope global"
    readonly property string cmd: "echo \"$(jc "+cmd_iw_link+") [{\\\"bssid\\\":\\\"$("+cmd_iw_link+" | awk '$1==\"Connected\"{print $3}')\\\"}]  $("+cmd_ip_addr+")\" | jq -s '.[0] + .[1] + .[2] | reduce .[] as $item ({}; . *= $item)'"

    text: ""


    function restart_query() {
        iface_get_status.signal(9) // kill existing
        iface_get_status.running = true
        tmr_exec.restart()
    }

    Connections {
        target: Notifier

        function onDndEnabledChanged(): void {
            root.restart_query()
        }
    }


    Process {
        id: iface_get_status
        running: root.iface !== "" ? true : false
        command: ["sh", "-c", root.cmd]
        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( root.widget_debug ) console.debug("Wifi[" + root.iface + "]: OUT>" + stdout);

                if( stdout.length == 0 ) {
                    root.text_normal = root.icon_down
                    root.text_extended = root.icon_down
                    root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
                    root.color = Config.appearance.color_fg_disabled
                    return;
                }

                try {
                    const data = JSON.parse(stdout);
                    //const iface = data[1];
                    //const iw = data[0];
                    if( root.widget_debug ) console.debug("Wifi[" + root.iface + "]: JSON> " + JSON.stringify(data, null, 2))

                    if( data === undefined || data.operstate === undefined ) {
                        root.text_normal = root.icon_down
                        root.text_extended = root.icon_down
                        root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
                        root.color = Config.appearance.color_fg_disabled
                        return;
                    }

                    switch( data.operstate ) {
                        case "UP":
                        case "UNKNOWN":
                            //root.text = "UP"
                            const ip = data.addr_info[0];


                            // ["󰤫", "󰤟", "󰤢", "󰤥", "󰤨"]
                            let icon = "?"
                            if( data.signal_dbm < -80 ) icon="󰤫"
                            else if( data.signal_dbm < -70 ) icon="󰤟"
                            else if( data.signal_dbm < -60 ) icon="󰤢"
                            else if( data.signal_dbm < -50 ) icon="󰤥"
                            else icon="󰤨"

                            if( ip === undefined ) {
                                // No IP address
                                root.text = icon + " no_address"
                                root.text_extended = root.text
                                root.color = Config.appearance.color_fg_warning
                            } else {
                                let x = "a";
                                /*
                                const ip_split = ip.local.split(".")
                                let ip_hex = (parseInt(ip_split[0]) <= 0xf ? "0" : "") + parseInt(ip_split[0]).toString(16);
                                ip_hex += (parseInt(ip_split[1]) <= 0xf ? "0" : "") + parseInt(ip_split[1]).toString(16);
                                ip_hex += (parseInt(ip_split[2]) <= 0xf ? "0" : "") + parseInt(ip_split[2]).toString(16);
                                ip_hex += (parseInt(ip_split[3]) <= 0xf ? "0" : "") + parseInt(ip_split[3]).toString(16);
                                */

                                var s_ip = Config.incognito_mode ? ip.local.replace(/[0-9]+/g, "x") : ip.local
                                var s_ssid = Config.incognito_mode ? "my_ssid" : data.ssid
                                var s_signal = "<sub>" + data.signal_dbm + "</sub>"
                                var s_ip_prefix =  "<sub>/" + ip.prefixlen + "</sub>"

                                // Hide details in DND mode
                                if( Notifier.dndEnabled ) {
                                    s_ip = s_signal = s_ip_prefix = s_ssid = ""
                                }

                                root.text_normal = icon + s_signal + " <strong>" + s_ssid + "</strong> " + s_ip; // + "/" + ip_hex
                                root.text_extended = root.text_normal + s_ip_prefix
                                root.color = Config.appearance.color_fg_active
                            }
                            break;

                        case "DOWN":
                            root.text_normal = root.icon_down
                            root.text_extended = root.icon_down
                            root.color = Config.appearance.color_fg_disabled
                            break;

                        default:
                            console.warn("Wifi[" + root.iface + "]: Unhandled iface state: " + data.operstate)
                            console.debug("Wifi[" + root.iface + "]: JSON> " + JSON.stringify(data, null, 2))
                            break;
                    }

                    //console.log("[HyprMaster] Config loaded successfully")
                } catch (e) {
                    console.error("Wifi[" + root.iface + "]: Failed to parse JSON output:", e)
                }

                root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
            }
        }
    }

    Timer {
        id: tmr_exec
        interval: root.interval * 1000
        running: root.interval ? true : false
        repeat: true
        onTriggered: iface_get_status.running = true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        hoverEnabled: true

        onEntered: {
            root.text = root.text_extended;
            root.mouse_hovering = true;
        }
        onExited: {
            root.text = root.text_normal;
            root.mouse_hovering = false;
        }

        onClicked: (mouse)=> {
            const actionl = root.model.config.on_click ?? ""
            const actionr = root.model.config.on_click_right ?? ""
            const actionm = root.model.config.on_click_middle ?? ""

            switch( mouse.button ) {
                case Qt.RightButton:
                    if( actionr == "" ) return;
                    console.info("exec->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) return;
                    console.info("exec->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("exec->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;
            }

            if( root.iface.length ) iface_get_status.running = true
        }
    }

}

