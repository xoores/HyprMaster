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
    property string conn_name: widget_config?.name ?? ""
    property string icon_up: widget_config?.icon_up ?? "U"
    property string icon_down: widget_config?.icon_down ?? "D"
    property bool show_ip: widget_config?.show_ip ?? false

    property string text_normal: ""
    property string text_extended: ""
    property bool mouse_hovering: false;

    text: ""

    Process {
        id: iface_get_status
        running: root.conn_name !== "" ? true : false

        command: ["nmcli", "-t", "-f", "GENERAL.STATE,IP4.ADDRESS",
                  "connection", "show", "--active", root.conn_name]


        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( root.widget_debug ) console.debug("NMConn[" + root.conn_name + "]: OUT>" + stdout);

                let st = ""
                let ips = []
                for (const line of stdout.split("\n")) {
                    const i = line.indexOf(":")
                    if (i < 0) continue
                    const key = line.slice(0, i)
                    const val = line.slice(i + 1)
                    if (key === "GENERAL.STATE")
                        st = val
                    else if (key.startsWith("IP4.ADDRESS"))   // IP4.ADDRESS[1], [2], ...
                        ips.push(val.split("/")[0])           // drop the /prefix
                }


                if( st != "activated" ) {
                    root.text_normal = root.icon_down
                    root.text_extended = root.icon_down
                    root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
                    root.color = Config.appearance.color_fg_disabled
                    return;
                }


                root.text = "UP"
                const ip = ips[0];

                if( ip === undefined ) {
                    // No IP address
                    root.text_normal = root.icon_up + " no_address"
                    root.text_extended = root.text_normal
                    root.color = Config.appearance.color_fg_warning
                } else {
                    const ip_split = ip.split(".")
                    let ip_hex = parseInt(ip_split[0]).toString(16) + "" + parseInt(ip_split[1]).toString(16)
                    ip_hex += "" + parseInt(ip_split[2]).toString(16) + "" + parseInt(ip_split[3]).toString(16)

                    root.text_normal = root.icon_up;// + ip.local + "/" + ip_hex;
                    root.text_extended = root.icon_up + " " + ip

                    if( root.show_ip ) {
                        root.text_normal += " " + ip
                    }

                    root.color = Config.appearance.color_fg_active
                }

                //state = st
                //addresses = ips
                /*
                if( stdout.length == 0 ) {
                    root.text_normal = root.icon_down
                    root.text_extended = root.icon_down
                    root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
                    root.color = Config.appearance.color_fg_disabled
                    return;
                }

                try {
                    const iface = JSON.parse(stdout)[0];
                    if( root.widget_debug ) console.debug("NMConn[" + root.conn_name  + "]: JSON> " + JSON.stringify(iface, null, 2))

                    if( iface === undefined ) {
                        root.text_normal = root.icon_down
                        root.text_extended = root.icon_down
                        root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
                        root.color = Config.appearance.color_fg_disabled
                        return;
                    }

                    switch( iface.operstate ) {
                        case "UP":
                        case "UNKNOWN":
                            root.text = "UP"
                            const ip = iface.addr_info[0];
                            const ip_split = ip.local.split(".")
                            let ip_hex = parseInt(ip_split[0]).toString(16) + "" + parseInt(ip_split[1]).toString(16)
                            ip_hex += "" + parseInt(ip_split[2]).toString(16) + "" + parseInt(ip_split[3]).toString(16)

                            if( ip === undefined ) {
                                // No IP address
                                root.text = root.icon_up + " no_address"
                                root.color = Config.appearance.color_fg_warning
                            } else {
                                root.text_normal = root.icon_up;// + ip.local + "/" + ip_hex;
                                root.text_extended = root.icon_up + " " + ip.local + "<sub>/" + ip.prefixlen + "</sub>"

                                if( root.show_ip ) {
                                    root.text_normal += " " + ip.local
                                }

                                root.color = Config.appearance.color_fg_active
                            }
                            break;

                        case "DOWN":
                            root.text_normal = root.icon_down
                            root.text_extended = root.icon_down
                            root.color = Config.appearance.color_fg_disabled
                            break;

                        default:
                            console.warn("NMConn[" + root.conn_name + "]: Unhandled iface state: " + iface.operstate)
                            console.debug("NMConn[" + root.conn_name + "]: JSON> " + JSON.stringify(iface, null, 2))
                            break;
                    }

                    //console.log("[HyprMaster] Config loaded successfully")
                } catch (e) {
                    console.error("NMConn[" + root.conn_name + "]: Failed to parse ip output:", e)
                }
                */

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
            const actionl = root.model?.config?.on_click ?? ""
            const actionr = root.model?.config?.on_click_right ?? ""
            const actionm = root.model?.config?.on_click_middle ?? ""

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
                    console.info("exec->onClicked(MIDDLE): " + actionm);
                    Quickshell.execDetached(actionm);
                    break;

            }

            if( root.conn_name.length ) iface_get_status.running = true
        }
    }

}

