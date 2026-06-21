pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import "../config"
import "../services"

Item {
    id: root

    //required property var modelData

    required property string host
    property int interval: 5 * 1000

    property bool is_ok: false


    function restart_query() {
        exec_ip_resolver.signal(9) // kill existing
        exec_ip_resolver.running = true
        tmr_exec.restart()
    }

    Connections {
        target: Networking
        function onConnectivityChanged(): void { root.restart_query() }
    }

    Connections {
        target: Notifier
        function onDndEnabledChanged(): void { root.restart_query() }
    }


    Process {
        id: exec_ip_resolver
        running: root.host.length ? true : false
        command: ["ping", "-c1", "-n", "-q", "-W1", root.host ]
        stdout: StdioCollector {
            onStreamFinished: {
                //console.log(root.host + ">" + text)

                let stdout = text.trim()
                if( stdout.length < 7 ) {
                    //root.color = Config.appearance.color_fg_error
                    //root.text = root.host[0]
                    //tooltip.text = "No internet"
                    root.is_ok = false
                    return
                }

                root.is_ok = true
                //root.color = Config.appearance.color_fg_good
            }

        }
    }

    Timer {
        id: tmr_exec
        interval: root.interval
        running: root.interval ? true : false
        repeat: true
        onTriggered: exec_ip_resolver.running = true
    }
}
