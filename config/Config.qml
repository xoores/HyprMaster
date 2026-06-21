pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtQml.Models

import "BarConfig.qml"
import "AppearanceConfig.qml"

// Priority: Hardcoded defaults → User config.json

Singleton
{
    id: root

    property alias bar: adapter.bar
    property alias appearance: adapter.appearance
    property alias icons: adapter.icons
    property alias screenshot: adapter.screenshot


    property bool incognito_mode: false

    property string ip_resolver: ""
    property list<string> icmp_monitor_hosts: []



    // Config file path
    readonly property string configPath: Quickshell.env("HOME") + "/.config/hyprmaster/config.json"


    function _assignValue( src, dst ): void {
        if( src !== undefined ) dst = src;
    }

    function _parseConfig(): void {
        const content = configFileView.text()
        if (!content || content.trim() === "") {
            console.info(`CFG: Config file does not exist / is empty - using defaults`)
            return
        }

        try {
            console.info(`CFG: Loading config`)
            const config = JSON.parse(content)

            appearance.parse_config( config.appearance )
            bar.parse_config( config.widgets )
            icons.parse_config( config.icons )
            screenshot.parse_config( config.screenshot )


            incognito_mode = config.general.incognito_mode ?? false

            ip_resolver = config.general.ip_resolver ?? ""

            for ( const a of config?.general?.icmp_monitor_hosts ) {
                icmp_monitor_hosts.push( a )
            }


            console.log("[HyprMaster] Config loaded successfully")
        } catch (e) {
            console.error("[HyprMaster] Failed to parse config:", e)
        }

        // Dump config to pretty-printed JSON
        //console.info("xxxxx" +JSON.stringify(adapter, null, 2));
    }

    // Debounce timer for config reload
    Timer {
        id: configReloadTimer
        interval: 100
        repeat: false
        onTriggered: configFileView.reload()  // Reload file, then onLoaded fires
    }

    // Config file with live watching
    FileView {
        id: configFileView
        path: root.configPath
        watchChanges: true
        onFileChanged: configReloadTimer.restart()
        onLoaded: root._parseConfig()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                console.log("[HyprMaster] No config file at:", root.configPath, "- using defaults")
            } else {
                console.error("[HyprMaster] Config load failed:", FileViewError.toString(error))
            }
        }

        onSaveFailed: error => console.error("[HyprMaster] Failed to save file:", FileViewError.toString(error))

        JsonAdapter {
            id: adapter

            property BarConfig          bar: BarConfig {}
            property AppearanceConfig   appearance: AppearanceConfig {}
            property IconsConfig        icons: IconsConfig {}
            property ScreenshotConfig   screenshot: ScreenshotConfig {}
        }
    }
}
