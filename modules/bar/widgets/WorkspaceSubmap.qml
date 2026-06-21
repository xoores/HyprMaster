//pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Widgets

import "../../../components"
import "../../../config"
import "../../../services"

StyledLabel {
    id: root
    //required property var modelData
    //required property HyprlandMonitor monitor
    //required property var model


    padding: 2
    text:  Hypr.submap
    visible: Hypr.submap != ""
    Layout.minimumWidth: 24
    Layout.minimumHeight: 24
    color: Config.appearance.color_fg_error

    background: Item {
        Rectangle {
            height: 40
            anchors.fill: parent
            color: Config.appearance.color_bg
        }

        Rectangle {
            color: Config.appearance.color_accent_active
            height: 2
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }
    }
}
