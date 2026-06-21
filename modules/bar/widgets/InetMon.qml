pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import "../../../components"
import "../../../config"
import "../../../services"


StyledText {
    id: root
    required property var model


    /*
    property int interval: (widget_config?.interval ?? 5) * 1000
    property string ip_resolver: widget_config?.ip_resolver ?? ""
    */

    property list<string> exec_target: widget_config?.exec ?? []

    /*
    property string aditional_hosts: ""
    property string aditional_hosts_tooltip: ""
    property string public_ip: ""
    //property string internet_status: "Unknown"
    */

    text: PublicIP.public_ip + "<sub> " + ICMP.aditional_hosts + "</sub>";
    color: PublicIP.color
    rightPadding: 0


    /*
    // Aditional hosts monitoring ----------------------------------------------------------------------
    //
    // We want to have N aditional hosts to monitor - however I could not figure out a better way to
    // make this work. The goal is to check result of all ICMP requests and if all hosts are OK I
    // just want to see green number (number of all OK checks). If one or more fails, I want to see
    // first letters of each host in green (=OK) or red (=timeout)
    Repeater {
        id: monitors
        model: root.widget_config?.monitor_hosts

        ICMPmonitor{ }
    }
    Timer {
        id: tmr_monitors
        interval: 1000
        running: root.interval ? true : false
        repeat: true
        onTriggered: {
            //console.log(">" + monitors.count)
            var h = ""
            var h_tooltip = ""
            var ok_count = 0
            for( var x=0 ; x<monitors.count ; x++ ) {
                var m = monitors.itemAt(x)
                var c = Config.appearance.color_fg_error
                var v = "Unavailable"
                if( m.is_ok ) {
                    ok_count++
                    c = Config.appearance.color_fg_good
                    v = "Available"
                }

                h += "<font color=\"" + c + "\">" + m.host[0] + "</font>"
                h_tooltip += "<br>" + m.host + ": <font color=\"" + c + "\">" + v + "</font>"
                //console.log(">" + m.host)
            }

            if( ok_count == monitors.count ) {
                root.aditional_hosts = "<font color=\"" + Config.appearance.color_fg_good + "\">" + ok_count + "</span>"
            } else {
                root.aditional_hosts = h
            }

            root.aditional_hosts_tooltip = h_tooltip
        }
    }
    */


    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
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

            //if( root.exec_target.length ) exec_app.running = true
        }
    }

    StyledTooltip {
        id: tooltip
        anchorItem: ma
        text: "<strong>" + PublicIP.internet_status + "</strong><br>" + ICMP.aditional_hosts_tooltip
    }
}

