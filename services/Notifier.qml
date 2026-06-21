pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Services.Notifications

import "../components"
import "../config"

import "../config/Emoji.js" as Emoji

Singleton
{
    id: root
    reloadableId: "notifier"
    property list<QtObject> activeNotifications: []
    readonly property var notificationCount: activeNotifications.length
    property bool dndEnabled: false

    signal notificationReceived(var smartNotifObject)
    signal notificationClosed(var smartNotifObject)

    // We could "pre-compile" the regexps, but since this will not be called too many times
    // I don't think we need to bother
    function processEmojis( message: string ): string {
        for( var x=0 ; x<Emoji.EDICT.length ; x++ ) {
            var vals = Emoji.EDICT[x].alias.join(":|:").replace(/\+/g, "\\+")
            var re = new RegExp("(:" + vals + ":)", 'gi' )
            message = message.replace(re, Emoji.EDICT[x].emoji)
        }
        return message
    }

    function clearAllNotifs() {
        const allSmartNotifs = [...root.activeNotifications];
        for (const notif of allSmartNotifs) {
            notif.notification.dismiss();
        }
    }


    function toggleDnd() {
        dndEnabled = !dndEnabled;
        console.info("NOTIFY-DND: " + dndEnabled)
    }

    NotificationServer {
        id: notifServer

        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: originalNotif => {
            originalNotif.tracked = true;

            const newSmartNotif = notifComp.createObject(root, {
                notification: originalNotif
            });

            root.activeNotifications.push(newSmartNotif);
            root.notificationReceived(newSmartNotif);
        }
    }

    component Notif: QtObject {
        id: notifComponent

        required property Notification notification

        property string summary: ""
        property string body: ""
        property string appIcon: ""
        property string appName: ""
        property string image: ""
        property var urgency: NotificationUrgency.Normal
        property real expireTimeout: 5000
        property int notifId: 0
        property var displayActions: []

        onNotificationChanged: {
                if (!notification) return;

                summary = notification.summary;
                expireTimeout = (notification.expireTimeout > 2000) ? notification.expireTimeout : 10000
                urgency = notification.urgency ?? NotificationUrgency.Normal
                body = notification.body.trim();
                appIcon = notification.appIcon.replace("file://", "");
                appName = notification?.appName;
                image = notification.image.replace("file://", "");
                notifId = notification.id;

                console.log("NOTIFIER[" + appName + "|" + expireTimeout + "|" + urgency + "]: " + summary)

                if( body ) {
                    // For some reason Chrome sends URL of the webpage that sent a notification so it
                    // looks like 'mattermost.com\n\n@user: hello buddy' and I really don't like
                    // that. Let's remove the first URL of the message if its there
                    if( ["Vivaldi", "Chrome"].includes(appName) ) {
                        body = body.replace(/^<a[^>]+>[^>]+>\n\n@/, "@")
                    }

                    body = body.replace(/\n/g, "<br>") // Need to convert \n to proper HTML entity
                    body = root.processEmojis( body )
                    console.log("NOTIFIER: '" + body + "'")
                }

                var newActions = [];
                if (notification.actions) {
                    for (var i = 0; i < notification.actions.length; i++) {
                        console.log("NOTIFIER-ACTION: '" + notification.actions[i].text + "'")
                        newActions.push({
                        "text": notification.actions[i].text
                        });
                    }
                }
                displayActions = newActions;
            }

            function invokeAction(index) {
                if (notification && notification.actions && index >= 0 && index < notification.actions.length) {
                    notification.actions[index].invoke();
                }
            }

        readonly property date time: new Date()
        readonly property string timeStr: time.toLocaleTimeString([], {
            hour: '2-digit', minute: '2-digit' })

        readonly property Connections conn: Connections {
            target: notifComponent.notification ? notifComponent.notification.Retainable : null
            function onDropped(): void {
                console.log("onDropped()")
                root.notificationClosed(notifComponent);
                const index = root.activeNotifications.indexOf(notifComponent);
                if (index > -1) {
                    root.activeNotifications.splice(index, 1);
                }
                notifComponent.destroy(500);
            }
        }
    }

    Component {
        id: notifComp
        Notif {}
    }
}
