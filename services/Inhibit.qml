pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"
import "../config"

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled)
            props.enabledSince = new Date();
    }

    /*
    function get_color(): string {
        return root.enabled ? Config.appearance.color_fg_warning : Config.appearance.color_fg;
    }

    function get_icon(): string {
        return root.enabled ? "󰹑 󰍀" : "󰹑";
    }
    */

    function toggle(): void {
        root.set(!root.enabled)
    }

    function set(state: bool): void {
        console.debug("InhibitSvc: Setting inhibit to " + state)
        root.enabled = state
    }


    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    /*
    LazyLoader {
        active: props.enabled

         PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }
    */


    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            mask: Region {}
        }
    }


    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            root.toggle()
        }

        function enable(): void {
            root.set(true);
        }

        function disable(): void {
            root.set(false);
        }
    }
}
