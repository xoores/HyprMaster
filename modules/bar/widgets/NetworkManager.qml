pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "../../../components"
import "../../../config"
import "../../../services"

StyledText {
    id: root
    required property var model

    // Need either "name" (NM connection name) or "iface" (wlan0, ...)
    property string conn_name: widget_config?.name ?? ""
    property string iface: widget_config?.iface ?? ""
    property string icon_up: widget_config?.icon_up ?? "U"
    property string icon_down: widget_config?.icon_down ?? "D"
    property bool show_ip: widget_config?.show_ip ?? false

    property bool mouse_hovering: false

    readonly property var conn: root.conn_name !== "" ? (NM.connections[root.conn_name] ?? null)
                                                      : NM.connByIface(root.iface)

    readonly property bool up: conn?.up ?? false
    readonly property bool activating: conn?.activating ?? false
    readonly property bool is_wifi: conn?.is_wifi ?? false


    // ["󰤫", "󰤟", "󰤢", "󰤥", "󰤨"]
    readonly property string icon: {
        if ( !root.is_wifi ) {
            //console.debug("NetworkManager[" + root.iface + "] not a wifi")
            return root.icon_up;
        }

        if (root.conn.signal < 20) return "󰤫";
        else if (root.conn.signal < 40) return "󰤟";
        else if (root.conn.signal < 60) return "󰤢";
        else if (root.conn.signal < 80) return "󰤥";
        else return "󰤨";
    }

    readonly property string text_normal: {
        if (activating) return root.icon_down + " ...";
        if (!up) return root.icon_down;
        if (!conn.ip) return root.icon + " no_address";

        let t = root.icon;
        if (conn?.s_signal) t += "<sub>" + conn?.s_signal + "</sub>";
        if (conn?.s_ssid) t += " <strong>" + conn?.s_ssid + "</strong>";
        if (root.show_ip || is_wifi) t += " " + conn?.s_ip;
        return t;
    }

    readonly property string text_extended: up && conn.ip ? root.icon + conn?.s_signal
                                                            + (conn?.s_ssid ? " <strong>" + conn?.s_ssid + "</strong>" : "")
                                                            + " " + conn?.s_ip
                                                          : text_normal

    text: mouse_hovering ? text_extended : text_normal
    color: {
        if (root.activating) return Config.appearance.color_fg_warning;
        if (!root.up) return Config.appearance.color_fg_disabled;
        if (!root.conn.ip) return Config.appearance.color_fg_warning;
        return Config.appearance.color_fg_active;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true

        onEntered: root.mouse_hovering = true
        onExited: root.mouse_hovering = false

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

            NM.refresh()
        }
    }
}