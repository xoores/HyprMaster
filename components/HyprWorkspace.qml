pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick

import "../config"
import "../services"

QtObject {
    id: root
    property HyprlandWorkspace  ws

    property string             name: ""
    property bool               active: false
    property bool               urgent: false
    property bool               focused: false
    property int                id: -1
    property HyprlandMonitor    monitor: null
    property var                windows: []

    property bool               static_name: false
    property string             workspace_name: ""

    function refresh_icons() {
        if( static_name ) return;

        var icons=id + " "

        // The c-stuff is just crude way of rtrim...
        var c = windows.length
        for( const w of windows ) {
            c--
            if( w === "" ) continue
            var i = Config.icons.get_app_icon( w.toLowerCase() )
            if ( icons.includes(i) ) continue
            icons += i
            if( c ) icons += " "
        }
        workspace_name = icons
    }

    function activate() {
        ws.activate()
    }

    function update_from_ws(ws: HyprlandWorkspace) {
        if( !ws ) return

        name = ws?.name ?? ""
        active = ws?.active ?? false
        urgent = ws?.urgent ?? false
        focused = ws?.focused ?? false
        id = ws.id
        monitor = ws.monitor

        var ws_icon = Config.icons.get_workspace_icon(root.id)
        if( ws_icon !== "" ) {
            static_name = true
            workspace_name = ws_icon
        } else {
            workspace_name = "" + id + ""
        }
    }

    onWsChanged: {
        update_from_ws( ws )
        //console.log("HYPRWS-INIT[" + ws.id + "]")
    }
}