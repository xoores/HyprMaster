pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls

import "../../../components"
import "../../../config"
import "../../../services"


MouseArea {
    id: root
    required property SystemTrayItem modelData
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    implicitWidth: 16
    implicitHeight: 16

    //cursorShape: Qt.PointingHandCursor

    onClicked: event => {
        if (event.button === Qt.LeftButton) {
            root.modelData.activate();

        } else {
            if (root.modelData.hasMenu) {
                menuAnchor.open();
            } else {
                root.modelData.secondaryActivate();
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor
        menu: root.modelData?.menu
        anchor.window: window
        anchor.rect: window.mapFromItem(root, 0, root.height, root.width, root.width)
    }

    IconImage {
        id: icon
        asynchronous: true
        anchors.fill: parent
        anchors.centerIn: parent
        visible: status === Image.Ready
        smooth: true
        mipmap: true

        onStatusChanged: {
            if( icon.status == Image.Error ) {
                console.warn(icon.source + ": Failed to load")
            }
        }

        source: {
            let icon = root.modelData && root.modelData.icon;

            if (typeof icon === 'string' || icon instanceof String) {
                if (icon.includes("?path=")) {
                    const split = icon.split("?path=");
                    if (split.length !== 2)
                        return icon;
                    const name = split[0];
                    const path = split[1];
                    const fileName = name.substring(name.lastIndexOf("/") + 1);
                    //console.log("ICON1=" + "file://" + path + "/" + fileName)
                    return "file://" + path + "/" + fileName;
                }
                //console.log("ICON2=" + icon + " _ " + Quickshell.iconPath(icon))
                //return Quickshell.iconPath(icon);
                return icon;
            }

            console.warn("No icon for " + root.modelData.id)
            return "";
        }
    }

    StyledTooltip {
        anchorItem: root
        text: (root.modelData.tooltipTitle || root.modelData.title || root.modelData.tooltipDescription || "")
    }
}
