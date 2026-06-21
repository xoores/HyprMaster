pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../config"
import "../services"

StyledText {
    id: root

    readonly property var widget_config: model?.config
    property int widget_debug: widget_config?.debug ?? 0

    leftPadding: widget_config?.padding ?? 5
    rightPadding: widget_config?.padding ?? 5

    font.family: Config.appearance.font_family_material
}
