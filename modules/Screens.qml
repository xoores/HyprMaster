pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "bar"
import "../config"
import "../services"
import "../components"

Scope {
    id: root

    property var screens: []
    property bool rebuilding: false

    function snapshotScreens(): void {
        if (root.rebuilding) {
            resettle.restart();
            return;
        }

        const snapshot = [];
        for (let i = 0; i < Quickshell.screens.length; i++)
            snapshot.push(Quickshell.screens[i]);

        root.rebuilding = true;
        root.screens = snapshot;
        root.rebuilding = false;
    }

    Component.onCompleted: root.snapshotScreens()

    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            resettle.restart();
        }
    }

    Timer {
        id: resettle
        interval: 50
        repeat: false
        onTriggered: root.snapshotScreens()
    }

    Variants {
        model: root.screens
        //model: Quickshell.screens

        Scope {
            id: scope
            required property ShellScreen modelData
            // Force Screen re-creation whenever the actual Hyprland screen gets repositioned - othwerise it will be out of bounds and not visbible
            readonly property string screenGeometry: `${scope.modelData.x},${scope.modelData.y} ${scope.modelData.width}x${scope.modelData.height}`

            onScreenGeometryChanged: resurface.restart()

            Timer {
                id: resurface
                interval: 100
                repeat: false
                onTriggered: {
                    panel.active = false;
                    respawn.start();
                }
            }

            Timer {
                id: respawn
                interval: 1
                repeat: false
                onTriggered: panel.active = true
            }

            LazyLoader {
                id: panel
                active: true

                PanelWindow {
                    id: window
                    implicitHeight: Config.appearance.bar_height
                    color: Config.appearance.color_bg
                    screen: scope.modelData

                    anchors {
                        left: true
                        top: true
                        right: true
                    }

                    Loader {
                        id: content
                        anchors.fill: parent
                        active: window.visible

                        sourceComponent: BarWrapper {
                            screen: scope.modelData
                        }
                    }
                }
            }
        }
    }
}
