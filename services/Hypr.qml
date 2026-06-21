pragma Singleton
pragma ComponentBehavior: Bound



import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

import "../components"
import "../config"

Singleton
{
    id: root
    reloadableId: "hypr"

    readonly property var toplevels: Hyprland.toplevels
    //readonly property var workspaces: Hyprland.workspaces
    property ListModel workspaces: ListModel { objectName: "workspaces" }
    readonly property var monitors: Hyprland.monitors
    property var submap: ""

    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel?.wayland?.activated ? Hyprland.activeToplevel : null
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1


    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }


    signal configReloaded

    function workspacesByMonitor( monitor: HyprlandMonitor ): var {
        var ws = []
        for (var i = 0; i < root.workspaces.rowCount() ; i++ ) {
            var w = root.workspaces.get(i)
            if( w.monitor !== monitor || w.id < 0 ) continue;
            ws.push( w )
        }
        return ws
        //return w.monitor === root.monitor && w.id >= 0;
    }

    function deleteWorkspaceById( ws_id: int ): int {
        for (var i = 0; i < root.workspaces.rowCount() ; i++ ) {
            if( workspaces.get(i).ws.id === ws_id ) {
                console.log("HYPR-WS[" + ws_id + "]: Workspace @" + i + " deleted")
                workspaces.remove(i)
                return
            }
        }
    }


    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    /*
    function findWorkspace( name: string ): HyprWorkspace {
        for (var i = 0; i < root.workspaces.rowCount() ; i++ ) {
        //for ( const w of root.workspaces ) {
            var w = root.workspaces.get(i)
            if( w.name == name ) return w.ws
        }

        return null
    }
    */

    function findWorkspaceById( id: int ): HyprWorkspace {
        for (var i = 0; i < root.workspaces.rowCount() ; i++ ) {
        //for ( const w of root.workspaces ) {
            var w = root.workspaces.get(i)
            if( w.id == id ) return w.ws
        }

        return null
    }

    //function compareNumbers( a, b ) { return a - b }

    function createWorkspaceById(id: int) {
        var mw = hyprWorkspace.createObject(root, { id: id });
        workspaces.append( { id: id, ws: mw} )
    }

    function refreshWindows() {
        root.workspaces.clear()


        for ( const w of Hyprland.workspaces.values ) {
            if( w.id < 0 ) continue
            var mw = hyprWorkspace.createObject(root, { ws: w });
            workspaces.append( { id: w.id, ws: mw} )
        }

        for ( const w of Hyprland.toplevels.values ) {
            if( !w.workspace ) continue
            if( w.workspace.id < 0 || !w.wayland.appId ) continue
            var mw = findWorkspaceById( w.workspace.id )
            if( !mw ) {
                console.warn("Invalid WS for toplevel")
                continue
            }
            mw.update_from_ws( w.workspace )
            mw.windows.push( w.wayland.appId )
            mw.refresh_icons()
        }
    }

    /*
    // readonly property HyprKeyboard keyboard: extras.devices.keyboards.find(kb => kb.main) ?? null
    // readonly property bool capsLock: keyboard?.capsLock ?? false
    // readonly property bool numLock: keyboard?.numLock ?? false
    // readonly property string defaultKbLayout: keyboard?.layout.split(",")[0] ?? "??"
    // readonly property string kbLayoutFull: keyboard?.activeKeymap ?? "Unknown"
    // readonly property string kbLayout: kbMap.get(kbLayoutFull) ?? "??"
    // readonly property var kbMap: new Map()

    // readonly property alias extras: extras
    // readonly property alias options: extras.options
    // readonly property alias devices: extras.devices

    property bool hadKeyboard

    // function reloadDynamicConfs(): void {
    //     extras.batchMessage(["keyword bindlni ,Caps_Lock,global,caelestia:refreshDevices", "keyword bindlni ,Num_Lock,global,caelestia:refreshDevices"]);
    // }
    //
    // Component.onCompleted: reloadDynamicConfs()
    //
    // onCapsLockChanged: {
    //     if (!Config.utilities.toasts.capsLockChanged)
    //         return;
    //
    //     if (capsLock)
    //         Toaster.toast(qsTr("Caps lock enabled"), qsTr("Caps lock is currently enabled"), "keyboard_capslock_badge");
    //     else
    //         Toaster.toast(qsTr("Caps lock disabled"), qsTr("Caps lock is currently disabled"), "keyboard_capslock");
    // }
    //
    // onNumLockChanged: {
    //     if (!Config.utilities.toasts.numLockChanged)
    //         return;
    //
    //     if (numLock)
    //         Toaster.toast(qsTr("Num lock enabled"), qsTr("Num lock is currently enabled"), "looks_one");
    //     else
    //         Toaster.toast(qsTr("Num lock disabled"), qsTr("Num lock is currently disabled"), "timer_1");
    // }

    // onKbLayoutFullChanged: {
    //     if (hadKeyboard && Config.utilities.toasts.kbLayoutChanged)
    //         Toaster.toast(qsTr("Keyboard layout changed"), qsTr("Layout changed to: %1").arg(kbLayoutFull), "keyboard");
    //
    //     hadKeyboard = !!keyboard;
    // }
    */



    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            var refresh_windows = 0;
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            //console.log("EVENT: ", event.name)

            if (n === "configreloaded") {
                root.configReloaded();

            } else if (n === "submap") {
                root.submap = event.data

            } else if (n === "createworkspace") {
                root.createWorkspaceById( event.data )
                //Hyprland.refreshWorkspaces();

            } else if (n === "destroyworkspace") {
                root.deleteWorkspaceById( event.data )
                //Hyprland.refreshWorkspaces();

            } else if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                tmr_refreshWindows.start()

            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                tmr_refreshWindows.start()

            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();

            } else if (n.includes("workspace")) {
                console.log(n + "| " + event.data )
                Hyprland.refreshMonitors();
                Hyprland.refreshWorkspaces();
                tmr_refreshWindows.start()

            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                tmr_refreshWindows.start()
            }

            //Qt.callLater(() => {  })
        }
    }

    // We need to wait a little bit for data to refresh before we
    // can go through them
    Timer {
        id: tmr_refreshWindows
        interval: 50
        running: true
        repeat: false
        onTriggered: root.refreshWindows()
    }

    /*
    Connections {
        target: root.focusedMonitor

        function onLastIpcObjectChanged(): void {
            const specialName = root.focusedMonitor.lastIpcObject.specialWorkspace.name;

            if (specialName && specialName.startsWith("special:")) {
                root.lastSpecialWorkspace = specialName;
            }
        }
    }
    */


    Component {
        id: hyprWorkspace
        HyprWorkspace {}
    }


    // FileView {
    //     id: kbLayoutFile
    //
    //     path: Quickshell.env("CAELESTIA_XKB_RULES_PATH") || "/usr/share/X11/xkb/rules/base.lst"
    //     onLoaded: {
    //         const layoutMatch = text().match(/! layout\n([\s\S]*?)\n\n/);
    //         if (layoutMatch) {
    //             const lines = layoutMatch[1].split("\n");
    //             for (const line of lines) {
    //                 if (!line.trim() || line.trim().startsWith("!"))
    //                     continue;
    //
    //                 const match = line.match(/^\s*([a-z]{2,})\s+([a-zA-Z() ]+)$/);
    //                 if (match)
    //                     root.kbMap.set(match[2], match[1]);
    //             }
    //         }
    //
    //         const variantMatch = text().match(/! variant\n([\s\S]*?)\n\n/);
    //         if (variantMatch) {
    //             const lines = variantMatch[1].split("\n");
    //             for (const line of lines) {
    //                 if (!line.trim() || line.trim().startsWith("!"))
    //                     continue;
    //
    //                 const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s+([a-z]{2,}): (.+)$/);
    //                 if (match)
    //                     root.kbMap.set(match[3], match[2]);
    //             }
    //         }
    //     }
    // }

    /*
    IpcHandler {
        target: "hypr"

        function refreshDevices(): void {
            extras.refreshDevices();
        }
    }
    */

    // CustomShortcut {
    //     name: "refreshDevices"
    //     description: "Reload devices"
    //     onPressed: extras.refreshDevices()
    //     onReleased: extras.refreshDevices()
    // }

    // HyprExtras {
    //     id: extras
    // }
}
