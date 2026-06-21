pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../../components"
import "../../../config"
import "../../../services"


Rectangle {
    id: root
    required property HyprlandMonitor monitor
    height: workspaces.implicitHeight
    width: workspaces.implicitWidth
    color: "#4c7899"

    /*
    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    */

    RowLayout {
        anchors.fill: parent
        spacing: 0
        id: workspaces

        Repeater {

            // Workspaces on our monitor only - and skip any special workspace, too
            //model: Hypr.workspaces.values.filter((w) => {
            //    return w.monitor === root.monitor && w.id >= 0;
            //})

            model: Hypr.workspaces

            WorkspaceItem { monitor: root.monitor }
        }

        WorkspaceSubmap { }
    }

}
