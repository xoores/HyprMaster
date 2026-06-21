pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls


import "../../config"
import "../../services"
import "../../components"

Rectangle {
    id: root

    required property var notification

    property string defaultIcon: "root:/assets/notification.png"
    property real progress: 0.0
    property bool visibleProgress: false
    property int innerRadiusDiv: 4
    property bool dismissPressed: closeBtnMouseArea.pressed
    property int action_activate_index: -1

    signal dismissClicked
    signal actionInvoked(int index)

    implicitHeight: contentLayout.implicitHeight - 20; //(root.theme.dimensions.spacingLarge * 2)
    radius: Config.appearance.radius / 4
    color: {
        if( root.notification?.urgency == NotificationUrgency.Critical ) {
            return Config.appearance.color_primary_error
        } else if( root.notification?.urgency == NotificationUrgency.Low ) {
            return Config.appearance.color_primary_disabled
        }
        return Config.appearance.color_primary_active
    }

    function has_relevant_notifications() {
        if( !root.notification ||
            !root.notification.displayActions ||
            !root.notification.displayActions.length ) {
            //console.log("N1> No relevant notifications")
            return false
        }

        for( var x=0 ; x<root.notification.displayActions.length ; x++ ) {
            var action = root.notification.displayActions[x]
            console.log("N[" + x + "]: " + action.text)
        }

        if( root.notification.displayActions.length == 1 ) {
            var txt = root.notification.displayActions[0].text
            if( txt == "Activate" || txt == "Show Inbox" ) {
                // only one action => don't display button and use left click instead
                action_activate_index = 0
                console.log("N2> No relevant notifications: '" + txt + "'")
                return false
            }
        }

        if( root.notification.displayActions.length == 2 ) {
            // Two actions: Activate & Settings -> use just activate and ignore settings
            // this is used by chrome for IM notifications. Settings is irrelevant as it
            // just opens up chrome settings...
            if( root.notification.displayActions[0].text == "Activate" &&
                    root.notification.displayActions[1].text == "Settings" ) {
                action_activate_index = 0
                console.log("N3> No relevant notifications: 'Activate'")
                return false
            }
        }

        console.log("N> HAS relevant notifications!")
        return true
    }

    height: {
        var h = contentLayout.implicitHeight + 16
        //if( has_relevant_notifications() ) h *= 2
        return h;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                if( root.action_activate_index >= 0 ) {
                    var act = root.notification.displayActions[root.action_activate_index]
                    console.log("NOTIFICATION ACTIVATE DEFAULT: " + act.text)
                    root.actionInvoked(root.action_activate_index)
                    return
                }

                console.log("NOTIFICATION ACTIVATE")
                for( const n of root.notification.displayActions ) {
                    console.log(">>" + n.text ?? "NO_LABEL"  )
                }


            } else {
                console.log("Notification dismiss by right click")
                root.dismissClicked();
                enabled = false;
            }
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        // -- 1. Header Row --
        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Item {
                width: 20
                height: 20
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 5

                CircularProgress {
                    id: dismissProgress
                    anchors.centerIn: parent
                    width: parent.width + 2
                    height: parent.height + 2
                    thickness: 2
                    margin: 1
                    value: root.progress
                    foregroundColor: Config.appearance.color_accent_active
                    backgroundColor: Config.appearance.color_primary_inactive
                    visible: root.visibleProgress
                    enableAnimation: false
                }

                Text {
                    id: closeBtn
                    text: ""
                    font.family: Config.appearance.font_family_material
                    font.pixelSize: 14
                    anchors.centerIn: parent
                    color: Config.appearance.color_accent_active
                }

                MouseArea {
                    id: closeBtnMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        console.log("DISMISS")
                        root.dismissClicked();
                        enabled = false;
                    }
                }
            }

            StyledText {
                text: root.notification ? root.notification?.summary : ""
                font.pixelSize: 16
                font.bold: true
                color: Config.appearance.color_accent_active
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root?.notification?.timeStr ?? ""
                font.pixelSize: 12
                color: "#AAFFFFFF"
                Layout.alignment: Qt.AlignTop
            }
        }

        // -- 2. Summary Row --
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            visible: (root?.notification?.image || root?.notification?.summary) ?? false

            Image {
                id: notifImage

                property string rawIcon: root.notification ? (root.notification.image || root.notification.appIcon || "") : ""

                source: {
                    if (rawIcon === "")
                        return root.defaultIcon;


                    if (rawIcon.indexOf("/") !== -1 || rawIcon.indexOf("file://") === 0) {
                        //console.log("NOTIF-IMG1: '" + rawIcon + "'")
                        return rawIcon;
                    }

                    const icon = Quickshell.iconPath(rawIcon)

                    //console.log("NOTIF-IMG2: '" + rawIcon + "' -> '" + icon + "'")
                    return icon
                    //return "image://theme/" + rawIcon;
                }

                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignTop
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.warn("Notification Image Failed:", rawIcon, "- Reverting to default.");
                        source = root.defaultIcon;
                    }
                }
            }

            /*
            Text {
                text: notification ? notification?.summary : ""
                font.pixelSize: 12
                font.bold: true
                color: Config.appearance.color_accent_active
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            */

            // -- 3. Body Text --
            StyledText {
                id: bodyText
                text: root.notification ? root.notification?.body : ""
                visible: text !== ""
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                font.pixelSize: 14
                color: Config.appearance.color_accent_active
                Layout.fillWidth: true
            }
        }

        /*
        // -- 3. Body Text --
        Text {
            text: notification ? notification?.body : ""
            visible: text !== ""
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.pixelSize: 14
            color: Config.appearance.color_accent_active
            Layout.fillWidth: true
        }
        */

        // -- 4. Action Buttons --
        RowLayout {
            Layout.fillWidth: true
            visible: root.has_relevant_notifications() //(root?.notification?.displayActions.length > 0) ?? false
            spacing: 3

            Repeater {
                id: actionRepeater
                model: root.notification ? root.notification.displayActions : []

                delegate: Button {
                    id: b
                    required property var modelData
                    required property int index
                    visible: b.modelData.text !== ""

                    contentItem: Text {
                        text: b.modelData.text ?? ""
                        color: "black"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }


                    //property int groupRadius: root.theme.dimensions.elementRadius / Consts.M3_BUTTON_RADIUS_DIVISOR

                    //text: modelData.text !== "" ? modelData.text : "Do Action"
                    Layout.fillWidth:  true
                    //textElide: Text.ElideRight
                    onClicked: {
                        console.log("NOTIF-ACTION[" + root.notification?.appName + "]: " + index + " (" + modelData?.text + ")")
                        root.actionInvoked(index)
                    }

                    //topLeftRadius: index === 0 ? groupRadius : groupRadius / root.innerRadiusDiv
                    //bottomLeftRadius: index === 0 ? groupRadius : groupRadius / root.innerRadiusDiv
                    //topRightRadius: index === actionRepeater.count - 1 ? groupRadius : groupRadius / root.innerRadiusDiv
                    //bottomRightRadius: index === actionRepeater.count - 1 ? groupRadius : groupRadius / root.innerRadiusDiv
                }
            }
        }
    }
}