pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Networking


import "../../notifications" as Notifications

import "../../../components"
import "../../../services"
import "../../../config"


StyledText {
    id: root
    required property var model

    property bool scroll_latch: false
    property int scroll_latch_duration: widget_config?.scroll_delay ?? 0

    text: (Notifier.dndEnabled ? "" : "") + "<sub>" + Notifier.notificationCount + "</sub>"
    color: Notifier.dndEnabled ? Config.appearance.color_fg_warning : Config.appearance.color_fg


    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: (mouse)=> {
            const actionl = root.model?.config?.on_click ?? ""
            const actionr = root.model?.config?.on_click_right ?? ""
            const actionm = root.model?.config?.on_click_middle ?? ""

            switch( mouse.button ) {
                case Qt.RightButton:
                    if( actionr == "" ) {
                        Notifier.clearAllNotifs();
                        Notifications.NotificationArea.closeWindow();
                        return;
                    }
                    console.info("notifIndi->onClicked(RIGHT) -> " + actionr);
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionr == "" ) {
                        Notifications.NotificationArea.toggleWindow(bar.screen);
                        return;
                    }
                    console.info("notifIndi->onClicked(LEFT) -> " + actionl);
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) {
                        Notifier.toggleDnd();
                        return;
                    }
                    console.info("notifIndi->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }
        }


        StyledTooltip {
            anchorItem: ma
            text: Notifier.dndEnabled ? "DND mode" : "Notifications enabled"
        }
    }
}

