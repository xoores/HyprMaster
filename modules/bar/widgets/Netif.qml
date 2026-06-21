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
    property bool show_ip: widget_config?.show_ip ?? false

    property string text_normal: ""
    property string text_extended: ""
    property bool mouse_hovering: false;

    text: ""

    Process {
        id: iface_get_status
        running: root.iface !== "" ? true : false
        command: ["ip", "-j", "-4", "addr", "show", "dev", root.iface, "scope", "global"]
        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( root.widget_debug ) console.debug("Netif[" + root.iface + "]: OUT>" + stdout);

                if( stdout.length == 0 ) {
                    root.text_normal = root.icon_down
                    root.text_extended = root.icon_down
                    root.text = root.mouse_hovering ? root.text_extended : root.text_normal;
                    root.color = Config.appearance.color_fg_disabled
                    return;
                }

                try {
                    const iface = JSON.parse(stdout)[0];
                    if( root.widget_debug ) console.debug("Netif[" + root.iface + "]: JSON> " + JSON.stringify(iface, null, 2))

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
                            console.warn("Netif[" + root.iface + "]: Unhandled iface state: " + iface.operstate)
                            console.debug("Netif[" + root.iface + "]: JSON> " + JSON.stringify(iface, null, 2))
                            break;
                    }

                    //console.log("[HyprMaster] Config loaded successfully")
                } catch (e) {
                    console.error("Netif[" + root.iface + "]: Failed to parse ip output:", e)
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
                    console.info("exec->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }

            if( root.iface.length ) iface_get_status.running = true
        }
    }

}

