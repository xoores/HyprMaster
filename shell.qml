//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=100000
//@ pragma UseQApplication

import QtQuick
import Quickshell
//import "config"
import "modules"
import "services"
import "modules/notifications"


ShellRoot {
    id: root

    property var notificationsInstance: null;

    OSD { }
    Screens { }
    Component {
        id: notificationsComponent
        Notifications { }
    }

    Timer {
        id: delayedStartTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            console.info("Starting up...")
            root.notificationsInstance = createGlobalWindow(notificationsComponent, "Notifications");

            ICMP.init()
        }


        function createGlobalWindow (component, name) {
            const instance = component.createObject(root);
            if (!instance)
                console.error(`CRITICAL: Failed to create ${name}!`);
            return instance;
        }
    }
}
