pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

import "../config"
import "../services"

Label {
    id: root
    readonly property var widget_config: model?.config
    property int widget_debug: widget_config?.debug ?? 0

    leftPadding: widget_config?.padding ?? 5
    rightPadding: widget_config?.padding ?? 5
    topPadding: 2

    renderType: Text.NativeRendering
    textFormat: Text.RichText

    color: Config.appearance.color_fg

    Layout.fillWidth: true
    Layout.fillHeight: true

    font {
        family: Config.appearance.font_family
        pixelSize: Config.appearance.font_size
        bold: false
    }

    Behavior on color {
        CAnim { }
    }

}
