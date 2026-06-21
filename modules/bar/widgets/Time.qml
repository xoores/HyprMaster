pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../../components"
import "../../../config"
import "../../../services"

StyledText {
    id: root

    required property var model
    readonly property string format_str: model.config?.format ?? "HH:mm [dd.MM]"

    text: Qt.formatDateTime(clock.date, format_str)

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }
}
