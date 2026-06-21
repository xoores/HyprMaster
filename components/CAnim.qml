pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick

import "../config"
import "../services"

ColorAnimation {
    duration: 800
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
}
