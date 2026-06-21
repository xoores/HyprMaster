pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "../../components"
import "../../config"
import "../../services"


Item {
    id: bar_wrapper
    anchors.fill: parent
    required property ShellScreen screen


    Rectangle {
        height: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: Config.appearance.color_bg_accent ?? ""
    }

    RowLayout {
        anchors.left: parent.left
        Bar {
            screen: bar_wrapper.screen
            widgets: Config.bar.widgets_left
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        Bar {
            screen: bar_wrapper.screen
            widgets: Config.bar.widgets_center
        }
    }

    RowLayout {
        anchors.right: parent.right

        Bar {
            screen: bar_wrapper.screen
            widgets: Config.bar.widgets_right
        }
    }
}
