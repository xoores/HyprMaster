pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../../components"
import "../../../config"
import "../../../services"
import "../../"

StyledText {
    id: root

    text: {
        if( Screenshot.isRecording ) return "󰑋";

        return Inhibit.enabled ? "󰹑 󰍀" : "󰹑";
    }
    color: {
        if( Screenshot.isRecording ) return Config.appearance.color_fg_error;

        return Inhibit.enabled ? Config.appearance.color_fg_warning : Config.appearance.color_fg;
    }

    //Screenshot { }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse)=> {
            const actionl = root.model?.config?.on_click ?? ""
            const actionr = root.model?.config?.on_click_right ?? ""
            const actionm = root.model?.config?.on_click_middle ?? ""

            switch( mouse.button ) {
                case Qt.RightButton:
                if( actionr == "" ) {
                    console.info("bt->onClicked(RIGHT) -> (default action - screenshot picker)")
                    if( Screenshot.isRecording ) {
                        Screenshot.stopRecording();
                    } else {
                        Screenshot.startRecording();
                    }

                    //console.log(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "picker", "open"])
                    //Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "picker", "open"]);
                    //Screenshot.openFreeze()
                } else {
                    console.info("bt->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                }
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) {
                        console.info("bt->onClicked(LEFT) -> (default action - screenshot picker)")
                        Screenshot.takeScreenshot(true)
                        //console.log(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "picker", "openFreeze"])
                        //Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "picker", "openFreeze"]);
                        //Screenshot.openFreeze()
                    } else {
                        console.info("bt->onClicked(LEFT) -> " + actionl)
                        Quickshell.execDetached(actionl);
                    }

                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) {
                        console.info("bt->onClicked(MIDDLE) -> (default action)")
                        Inhibit.toggle()
                    } else {
                        console.info("bt->onClicked(MIDDLE) -> " + actionm)
                        Quickshell.execDetached(actionm);
                    }
                    break;

            }

        }
    }

}
