pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "bar"
import "../config"
import "../services"
import "../components"


Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property ShellScreen modelData

        // a standard desktop window
        PanelWindow {
            id: window
            implicitHeight: Config.appearance.bar_height
            color: Config.appearance.color_bg
            screen: scope.modelData


            anchors {
                left: true
                top: true
                right: true
            }

            Loader {
                id: content
                anchors.fill: parent
                active: window.visible

                sourceComponent: BarWrapper {
                    screen: scope.modelData
                }
            }
        }
    }
}
