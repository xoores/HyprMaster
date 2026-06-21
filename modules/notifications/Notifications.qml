pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire



import "../bar"
import "../../config"
import "../../services"
//import "../../components"


PanelWindow {
    id: root

    implicitWidth: 400
    implicitHeight: Screen.height - 24; //ThemeManager.selectedTheme.dimensions.barHeight

    color: "transparent"
    visible: popupModel.count > 0

    exclusionMode: ExclusionMode.Ignore

    mask: Region {
        item: popupContainer
    }
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    margins {
        bottom: 30
        right: 30
        top: 70
        left: 30
    }

    anchors {
        right: true
        top: true
    }

    property ListModel notification_list: ListModel {
        id: popupModel
        objectName: "notification_list"
    }

    Connections {
        target: Notifier
        function onNotificationReceived( notification ) {
            if (Notifier.dndEnabled) return;

            //popupModel.insert(0, ntf);
            //console.log("NOTIF: Adding notification (" + notification + "), now have " + popupModel.count)

            popupModel.insert(0, {"smartNotif": notification});

            //Qt.callLater(() => {
            //    console.log("NOTIF: added notification, now have " + popupModel.count)
            //})

        }
        function onNotificationClosed(smartNotifObject) {
            for (let i = 0; i < popupModel.count; ++i) {
                if (popupModel.get(i).smartNotif === smartNotifObject) {
                    popupModel.remove(i);
                    break;
                }
            }
            //console.log("NOTIF: REMOVED notification, now have " + popupModel.count)
        }
    }

    component ToastNotificationPopup: Item {
        id: toastRoot
        required property var notification
        signal requestRemove

        width: notificationItem.width
        height: notificationItem.height

        transformOrigin: Item.Center
        opacity: 0
        scale: 0.9
        x: 150

        Component.onCompleted: {
            show();
            hideTimer.start();
        }

        function show() {
            parallelShowAnimation.start();
        }

        function hide() {
            hideTimer.stop();
            parallelHideAnimation.start();
        }

        layer.enabled: root.visible
        layer.smooth: true
        //layer.effect: Shadow {}

        SequentialAnimation {
            id: progressAnimation
            running: true
            loops: 1
            NumberAnimation {
                target: notificationItem
                property: "progress"
                from: 0
                to: 1
                duration: hideTimer.interval
                easing.type: Easing.Linear
            }
        }

        ParallelAnimation {
            id: parallelShowAnimation

            NumberAnimation {
                target: toastRoot
                property: "x"
                to: 0
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }

            NumberAnimation {
                target: toastRoot
                property: "scale"
                to: 1.0
                duration: 500
                easing.type: Easing.OutBack
            }

            NumberAnimation {
                target: toastRoot
                property: "opacity"
                to: 1
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            id: parallelHideAnimation
            onStopped: toastRoot.requestRemove()

            NumberAnimation {
                target: toastRoot
                property: "x"
                to: toastRoot.width * 0.5
                duration: 300
                easing.type: Easing.InBack
                easing.overshoot: 1.0
            }

            NumberAnimation {
                target: toastRoot
                property: "scale"
                to: 0.8
                duration: 300
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                target: toastRoot
                property: "opacity"
                to: 0
                duration: 250
                easing.type: Easing.InQuad
            }
        }

        Timer {
            id: hideTimer
            interval: toastRoot?.notification?.expireTimeout ?? 10000
            repeat: false
            onTriggered: hide()
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    notificationItem.progress = 0;
                    progressAnimation.stop();
                } else {
                    hideTimer.restart();
                    progressAnimation.start();
                    toastRoot.scale = 1.0;
                }
            }
        }

        NotificationItem {
            id: notificationItem
            width: 350
            visibleProgress: true
            notification: toastRoot.notification
            onDismissClicked: hide()
            //theme: ThemeManager.selectedTheme
            onActionInvoked: index => {
                if (toastRoot.notification) {
                    toastRoot.notification.invokeAction(index);
                }
                hide();
            }
        }
    }

    ListView {
        id: popupContainer

        implicitWidth: root.implicitWidth
        height: contentHeight

        spacing: 10
        model: popupModel
        interactive: false
        clip: false

        leftMargin: 25
        rightMargin: 25

        displaced: Transition {
            SpringAnimation {
                property: "y"
                spring: 3.0
                damping: 0.2
                epsilon: 0.25
            }
        }

        delegate: ToastNotificationPopup {
            width: 350
            required property int index
            notification: popupModel.get(index)?.smartNotif

            onRequestRemove: {
                //popupModel.remove(index);
                if (index >= 0 && index < popupModel.count) {
                    popupModel.remove(index);
                }
            }
        }
    }
}
