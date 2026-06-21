pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.SystemTray

import "../../../components"
import "../../../config"
import "../../../services"

Rectangle {
    id: root

    visible: height > 0
    height: layout.implicitHeight
    width: layout.implicitWidth
    color: "transparent"

    property int item_count: 0

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.topMargin: 1
        spacing: 2

        Repeater {
            id: items

            model: SystemTray.items

            TrayItem { }


            onItemRemoved: {
                root.item_count -= 1
                root.implicitWidth = 18*root.item_count
            }

            onItemAdded: {
                root.item_count += 1
                root.implicitWidth = 18*root.item_count
            }
        }
    }
}
