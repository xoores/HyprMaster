pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"
import "../config"

Singleton {
    id: root

    property string aditional_hosts: ""
    property string aditional_hosts_tooltip: ""
    property string public_ip: "<i>loading</i>"
    property string internet_status: "Unknown"

    property int interval: 5000 // 5s

    property string text: public_ip + "<sub> " + root.aditional_hosts + "</sub>";
    property string color: Config.appearance.color_fg

    function restart_query() {
        exec_ip_resolver.signal(9) // kill existing
        exec_ip_resolver.running = true
        tmr_exec.restart()
    }

    Connections {
        target: Networking

        function onConnectivityChanged(): void {
            console.warn("CONNECTIVITY_CHANGED")
            root.restart_query()
        }
    }

    Connections {
        target: Notifier

        function onDndEnabledChanged(): void {
            root.restart_query()
        }
    }

    Process {
        id: exec_ip_resolver
        running: Config.ip_resolver.length ? true : false
        command: ["wget", "--quiet", "--timeout=2", "-O-", Config.ip_resolver ]
        stdout: StdioCollector {
            onStreamFinished: {
                //console.log(">" + text)

                let stdout = text.trim()
                if( stdout.length < 7 ) {
                    root.color = Config.appearance.color_fg_error
                    root.public_ip = ""
                    root.internet_status = "No internet"
                    return
                }

                root.internet_status = "Internet available"

                // Hide details in DND mode
                if( Notifier.dndEnabled ) {
                    root.color = Config.appearance.color_fg_good
                    root.public_ip = ""
                    return
                }

                root.color = Config.appearance.color_fg
                root.public_ip = Config.incognito_mode ? "&lt;public_ip&gt;" : stdout

                //root.text = s_ip + "<sub>" + root.aditional_hosts + "</sub>";
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
