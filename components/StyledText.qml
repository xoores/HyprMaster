pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../config"
import "../services"

Text {
    id: root

    readonly property var widget_config: model?.config
    property int widget_debug: widget_config?.debug ?? 0

    leftPadding: widget_config?.padding ?? 5
    rightPadding: widget_config?.padding ?? 5
    topPadding: 2

    renderType: Text.NativeRendering
    textFormat: Text.RichText
    color: Config.appearance.color_fg

    property bool animate: false

    font {
        family: Config.appearance.font_family
        pixelSize: Config.appearance.font_size
        bold: false
    }

    Behavior on color {
        CAnim { }
    }

    Behavior on text {
        enabled: root.animate
        SequentialAnimation {
            Anim {
                to: 0.6
                easing.bezierCurve: [0.3, 0, 1, 1, 1, 1]
            }
            PropertyAction {}
            Anim {
                to: 1
                easing.bezierCurve: [0, 0, 0, 1, 1, 1]
            }
        }
    }

    component Anim: NumberAnimation {
        target: root
        property: "scale"
        duration: 400 / 2
        easing.type: Easing.BezierSpline
    }
}
