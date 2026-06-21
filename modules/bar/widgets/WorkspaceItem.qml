pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "../../../components"
import "../../../config"
import "../../../services"

StyledLabel {
    id: root
    //required property HyprlandWorkspace modelData
    //required property var model
    required property var modelData
    required property HyprlandMonitor monitor
    property HyprWorkspace ws: modelData.ws

    property bool isActive: monitor.activeWorkspace?.id === ws.id
    //property string ws_name: model.ws.name

    padding: 2
    text: ws.workspace_name
    //text:  ws_name
    Layout.minimumWidth: 24
    Layout.minimumHeight: 24
    visible: ws.monitor === monitor && ws.id >= 0



    background: Item {
        Rectangle {
            height: 40
            anchors.fill: parent
            color: root.isActive ?  Config.appearance.color_primary_active : Config.appearance.color_primary_inactive
        }

        Rectangle {
            color: ( root.isActive ? Config.appearance.color_accent_active  : Config.appearance.color_accent_inactive )
            height: 2
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.ws.activate()
    }
}
