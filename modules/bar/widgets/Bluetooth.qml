pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../../components"
import "../../../config"



RowLayout {
    id: root
    required property var model
    //spacing: Appearance.spacing.smaller / 2


    // Bluetooth icon
    StyledText {
        text: {
            if (!Bluetooth.defaultAdapter?.enabled) return "󰂲";
            if (Bluetooth.devices.values.some(d => d.connected)) return "󰂱";
            return "";
        }
        color:{
            if (!Bluetooth.defaultAdapter?.enabled) return Config.appearance.color_fg_disabled;
            if (Bluetooth.devices.values.some(d => d.connected)) return Config.appearance.color_fg_active;
            return Config.appearance.color_fg;
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (mouse)=> {
                const actionl = root.model?.config?.on_click ?? ""
                const actionr = root.model?.config?.on_click_right ?? ""
                const actionm = root.model?.config?.on_click_middle ?? ""

                switch( mouse.button ) {
                    case Qt.RightButton:
                        if( actionr == "" ) return;
                        console.info("bt->onClicked(RIGHT) -> " + actionr)
                        Quickshell.execDetached(actionr);
                        break;

                    case Qt.LeftButton:
                        if( actionl == "" ) return;
                        console.info("bt->onClicked(LEFT) -> " + actionl)
                        Quickshell.execDetached(actionl);
                        break;

                    case Qt.MiddleButton:
                        if( actionm == "" ) {
                            console.info("bt->onClicked(MIDDLE) -> (default action)")
                            if( Bluetooth.defaultAdapter === undefined ) return;
                            const bt_target_state = !Bluetooth.defaultAdapter.enabled

                            console.info("Bluetooth: Toggling (" + bt_target_state + ")")
                            Bluetooth.defaultAdapter.enabled = bt_target_state
                        } else {
                            console.info("bt->onClicked(MIDDLE) -> " + actionm)
                            Quickshell.execDetached(actionm);
                        }
                        break;

                }

            }
        }
    }


    RowLayout {
        spacing: 0

        // Connected bluetooth devices
        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected)
            }

            StyledText {
                id: device

                leftPadding: 2
                rightPadding: 2

                required property BluetoothDevice modelData

                text: root.getBluetoothIcon(modelData?.icon)
                color: Config.appearance.color_fg
            }
        }

    }

    function getBluetoothIcon(icon: string): string {
        if (icon.includes("headset") || icon.includes("headphones"))
            return "󰥰";
        if (icon.includes("audio"))
            return "󰦢";
        if (icon.includes("phone"))
            return "󰏳";
        if (icon.includes("mouse"))
            return "󰦋";
        if (icon.includes("keyboard"))
            return "";
        return "";
    }
}

