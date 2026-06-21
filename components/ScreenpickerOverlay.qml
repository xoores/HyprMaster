pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "../config"
import "../services"

Variants {
    id:root
    model: Quickshell.screens

    property bool freeze: true
    property bool active: false
    property bool actionRecording: false

    signal selectedRegion(real globalX, real globalY, real w, real h, var screen, real localX, real localY)
    signal selectedMonitor(string screenName)
    signal cancelled()

    LazyLoader {
        required property var modelData
        active: root.active

        ScreenshotOverlay {
            targetScreen: modelData
            doFreeze: root.freeze
            actionRecording: root.actionRecording

            onRegionSelected: (globalX, globalY, w, h, screen, localX, localY) => {
                root.selectedRegion(globalX, globalY, w, h, screen, localX, localY)
            }

            onOutputSelected: (screenName) => root.selectedMonitor(screenName);
            onCancelled:  root.cancelled()
        }
    }
}