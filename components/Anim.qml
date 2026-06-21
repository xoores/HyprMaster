pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick

import "../config"
import "../services"

NumberAnimation {
    duration: 400
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
}
