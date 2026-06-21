pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "../components"
import "../config"

Singleton {
    id: root

    property string aditional_hosts: ""
    property string aditional_hosts_tooltip: ""

    property var host_monitors: []

    Component {
        id: monitorComponent
        ICMPmonitor { }
    }

    function init() {
        for( const h of Config.icmp_monitor_hosts ) {
            const instance = monitorComponent.createObject(root, { host: h});
            if (instance) {
                root.host_monitors.push( instance )
                tmr_monitors.running = true
            }

        }
    }

    Timer {
        id: tmr_monitors
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            var h = ""
            var h_tooltip = ""
            var ok_count = 0
            for( var x=0 ; x<root.host_monitors.length ; x++ ) {
                var m = root.host_monitors[x]
                //console.log(">>> " + m)
                var c = Config.appearance.color_fg_error
                var v = "Unavailable"
                if( m.is_ok ) {
                    ok_count++
                    c = Config.appearance.color_fg_good
                    v = "Available"
                }

                h += "<font color=\"" + c + "\">" + m.host[0] + "</font>"
                h_tooltip += "<br>" + m.host + ": <font color=\"" + c + "\">" + v + "</font>"

            }

            if( ok_count == root.host_monitors.length ) {
                root.aditional_hosts = "<font color=\"" + Config.appearance.color_fg_good + "\">" + ok_count + "</span>"
            } else {
                root.aditional_hosts = h
            }

            root.aditional_hosts_tooltip = h_tooltip
        }
    }

}
