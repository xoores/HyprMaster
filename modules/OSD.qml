pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts


import "../config"
import "../services"
import "../components"

Scope {
    id: root

    enum DISPLAY_TARGET { Brightness = 0, Volume = 1, Mic = 2 }

    property int selected_display_target: OSD.DISPLAY_TARGET.Brightness
    property int display_value: -1 // 0-100%
    property string display_icon: ""
    property bool shouldShowOsd: false
    property string bar_color: "white"
    property bool ignored_first_brightness_change: false;

    Connections {
        target: Brightnessctl

        function onBrightnessChanged(brightness: int, icon: string) {
            if( !root.ignored_first_brightness_change ) {
                root.ignored_first_brightness_change = true
                return;
            }

            root.display_value = brightness
            root.display_icon = Brightnessctl.get_icon()
            root.bar_color = "white"
            root.show();
        }
    }


    Connections {
        target: Pw

        function onSinkVolumeChanged(volume: int, muted: bool, icon: string) {
            root.display_value = volume
            root.display_icon = icon
            root.bar_color = muted ? "gray" : "white"
            root.show();
        }

        function onSourceVolumeChanged(volume: int, muted: bool, icon: string) {
            root.display_value = volume
            root.display_icon = icon
            root.bar_color = "none"
            root.show();
        }
    }

    function show() {
        shouldShowOsd = true;
        hideTimer.restart();
    }

    function hide() {
        hideTimer.stop();
        shouldShowOsd = false;
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.hide()
    }

    // The OSD window will be created and destroyed based on shouldShowOsd.
    // PanelWindow.visible could be set instead of using a loader, but using
    // a loader will reduce the memory overhead when the window isn't open.
    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            id: osdWindow
            anchors.bottom: true
            margins.bottom: screen.height / 10
            exclusiveZone: 0

            implicitWidth: 300
            implicitHeight: 250
            color: "transparent"

            // An empty click mask prevents the window from blocking mouse events.
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "#cc000000"

                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 15
                    }

                    StyledText {
                        id: icon
                        //anchors.top: parent.top
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 200
                        topPadding: -50
                        bottomPadding: -70
                        text: root.display_icon
                    }

                    Rectangle {
                        // Stretches to fill all left-over space
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter

                        implicitHeight: 20
                        radius: 5
                        color: root.bar_color == "none" ? "transparent" : "#50ffffff"

                        Rectangle {
                            color: root.bar_color

                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }

                            implicitWidth: parent.width * (root.display_value/100)
                            radius: parent.radius
                        }
                    }
                }
            }
        }
    }
}
