pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Networking

import "../components"
import "../config"

Singleton {
    id: root
    reloadableId: "NM"

    // main logic:
    // - procMonitor receives NetworkManager events and every time something happens fires procActive
    //   - There is a 300ms debounce timer if something hits the fan...
    //   - There also is a 5s restart timer when procMonitor exits
    // - procActive gets list of all active connections fires procConnDetails
    // - procConnDetails parses all the details & stuffs them into nm_connections[]
    // - nm_connections[] is then transformed to connections[] by adding wifi from QuickShell
    // - connections[] is used as a binding object - either directly or through connByIface()

    // Active NM connections (all of them) so we can pick whatever we want from our widgets without having to poll
    // status from each widget (times bar count since they are not singletons! yikes).
    property var nm_connections: ({})

    readonly property var connections: {
        const all = Object.assign({}, root.nm_connections);

        // Add QuickShell Wifi connections to our collection
        for (const d of Networking.devices.values) {
            if (d.type !== DeviceType.Wifi) continue;
            const nets = d.networks?.values ?? [];
            const n = nets.find(n => n.connected) ?? nets.find(n => n.stateChanging) ?? null;
            if (!n) continue;

            const base = Object.values(root.nm_connections)
                         .find(c => !c.vpn && (c.iface === d.name || c.device === d.name))
                         ?? { name: n.name, vpn: false, iface: d.name, device: d.name, addrs: [], ip: "", prefix: "" };

            const sig = Math.round(n.signalStrength * 100);
            all[base.name] = Object.assign({}, base, {
                state: n.state === ConnectionState.Connected ? "activated"
                     : n.state === ConnectionState.Connecting ? "activating"
                     : n.state === ConnectionState.Disconnecting ? "deactivating" : base.state,
                ssid: n.name,
                signal: sig,
                is_wifi: true,
                signal_dbm: sig - 120  // NM calculates wifi% by mapping -90..-20dBm directly to 30..100%
            });
        }

        // Finish by preparing all the fields for later use in widgets...
        for (const name in all) {
            const c = all[name];
            c.up = c.state === "activated";
            c.activating = c.state === "activating";
            c.is_wifi = c.is_wifi ?? false;

            c.s_ip = Notifier.dndEnabled || !c.ip ? ""
                     : Config.incognito_mode ? c.ip.replace(/[0-9]+/g, "x") : c.ip;
            c.s_ssid = Notifier.dndEnabled || !c.is_wifi ? ""
                       : Config.incognito_mode ? "my_ssid" : c.ssid;
            c.s_signal = Notifier.dndEnabled || !c.is_wifi ? "" : c.signal_dbm;
        }
        return all;
    }

    property list<string> active_names: []
    property bool pending: false

    function connByIface(iface) {
        const all = Object.values(root.connections).filter(c => c.iface === iface || c.device === iface);
        return all.find(c => !c.vpn) ?? all[0] ?? null;
    }

    function refresh(): void {
        if (procActive.running || procConnDetails.running) {
            root.pending = true;
            return;
        }
        root.pending = false;
        procActive.running = true;
    }

    function refreshDone() {
        if (root.pending) Qt.callLater(root.refresh);
    }

    Component.onCompleted: refresh()

    Process {
        id: procMonitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: tmr_debounce.restart()
        }

        onExited: (exitCode, exitStatus) => {
            tmr_monitorRestart.start()
        }
    }

    Process {
        id: procActive
        command: ["nmcli", "-t", "-e", "no", "-f", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active_names = text.split("\n").filter(n => n.length);
                if (!root.active_names.length) {
                    root.nm_connections = {};
                    root.refreshDone();
                    return;
                }
                procConnDetails.running = true;
            }
        }
    }

    // TODO: maybe convert the list to QtObject and refresh instead of creating a new array each time? Would need to implement search
    // etc though - would it be better?
    Process {
        id: procConnDetails
        command: ["nmcli", "-t", "-e", "no", "-f",
                    "GENERAL.NAME,GENERAL.STATE,GENERAL.VPN,GENERAL.DEVICES,GENERAL.IP-IFACE,IP4.ADDRESS,DHCP4.OPTION,ipv4.addresses",
                    "connection", "show", "--active"].concat(root.active_names.reduce((a, n) => a.concat(["id", n]), []))
        stdout: StdioCollector {
            onStreamFinished: {
                const conns = {};
                for (const block of text.split("\n\n")) {
                    const c = { name: "", state: "", vpn: false, iface: "", device: "", addrs: [], ip: "" };
                    for (const line of block.split("\n")) {

                        //console.debug("NM-detail: '" + line + "'")

                        const i = line.indexOf(":"); // If we just use split(":"), it'll break with ipv6...
                        if (i < 0) continue;
                        const key = line.slice(0, i).replace(/\[\d+\]$/, "");
                        const val = line.slice(i + 1);

                        if( val == "" ) continue;

                        if (key === "GENERAL.NAME") c.name = val;
                        else if (key === "GENERAL.STATE") {
                            //console.debug("NM-detail: '" + val + "'")
                            c.state = val;
                        }
                        else if (key === "GENERAL.VPN") c.vpn = val === "yes";
                        else if (key === "GENERAL.DEVICES") c.device = val.split(",")[0];
                        else if (key === "GENERAL.IP-IFACE") c.iface = val;
                        else if (key === "IP4.ADDRESS") c.addrs.push("." + val.split("/")[0]);
                        else if (key === "ipv4.addresses" ) c.ip = ":" + val.split(",")[0].split("/")[0];
                        else if (key === "DHCP4.OPTION" && val.startsWith("ip_address = ")) c.ip = val.slice(13);
                        //else console.warn("NM-detail: Unhandled key '" + key + "' in '" + line + "'")
                    }
                    if (c.name) conns[c.name] = c;
                }


                const all = Object.values(conns);
                for (const c of all) {
                    if (c.ip) continue;
                    if (c.vpn) {
                        const parentIps = all.filter(p => !p.vpn && p.iface === c.iface).map(p => p.ip);
                        c.ip = c.addrs.find(a => !parentIps.includes(a)) ?? "";
                    } else {
                        c.ip = c.addrs[0] ?? "";
                    }
                }

                root.nm_connections = conns;
                root.refreshDone();
            }
        }
    }

    Timer {
        id: tmr_debounce
        interval: 300
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: tmr_monitorRestart
        interval: 5000
        repeat: false
        onTriggered: procMonitor.running = true
    }
}
