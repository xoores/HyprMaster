pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import "../config"
import "../services"

Scope {
    id: root
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

        // I'm an idiot - the previous version falsely flagged unreachable hosts as OK since
        // ping always prints out a summary (which is obviously longer than 7 characters)... Ouch
        onExited: (exitCode, exitStatus) => {
            //console.info("ICMP[" + root.host + "]: exitStatus=" + exitStatus + "  exitCode=" + exitCode)
            root.is_ok = (exitStatus === 0 && exitCode === 0)
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
