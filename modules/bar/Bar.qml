pragma ComponentBehavior: Bound


import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import QtQml.Models

import "widgets"

import "../../components"
import "../../config"
import "../../services"

RowLayout {
    id: bar
    required property ShellScreen screen
    required property ListModel widgets
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    Layout.preferredWidth: implicitWidth  // force proper sizing



    Repeater {
        model: bar.widgets

        DelegateChooser {
            role: "type"

            DelegateChoice { roleValue: "battery";         delegate: Battery {} }
            DelegateChoice { roleValue: "bluetooth";       delegate: Bluetooth {} }
            DelegateChoice { roleValue: "backlight_ext";   delegate: BacklightExt {} }
            DelegateChoice { roleValue: "backlight";       delegate: Backlight {} }
            DelegateChoice { roleValue: "datetime";        delegate: Time {} }
            DelegateChoice { roleValue: "exec";            delegate: Exec {} }
            DelegateChoice { roleValue: "inhibitor";       delegate: Inhibitor {} }
            DelegateChoice { roleValue: "netif";           delegate: Netif {} }
            DelegateChoice { roleValue: "tray";            delegate: Tray {} }
            DelegateChoice { roleValue: "volume";          delegate: Volume {} }
            DelegateChoice { roleValue: "microphone";      delegate: Microphone {} }
            DelegateChoice { roleValue: "volume_ext";      delegate: VolumeExt {} }
            DelegateChoice { roleValue: "wifi";            delegate: Wifi {} }
            DelegateChoice { roleValue: "inetmon";         delegate: InetMon {} }
            DelegateChoice { roleValue: "notifindicator";  delegate: NotifIndicator {} }
            DelegateChoice { roleValue: "workspaces";      delegate: Workspaces { monitor: bar.monitor } }
        }
    }
}
