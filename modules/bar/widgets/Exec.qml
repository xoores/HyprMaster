pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import "../../../components"
import "../../../config"
import "../../../services"


StyledText {
    id: root
    required property var model


    property int exec_delay: widget_config?.delay ?? 0
    property list<string> exec_target: widget_config?.exec ?? []

    text: ""

    Process {
        id: exec_app
        running: root.exec_target.length ? true : false
        command: root.exec_target
        stdout: StdioCollector {
            onStreamFinished: {
                let stdout = text.trim()
                if( stdout.length == 0 ) return;
                root.text = text.trim();
            }
        }
    }

    Timer {
        id: tmr_exec
        interval: root.exec_delay
        running: root.exec_delay ? true : false
        repeat: true
        onTriggered: exec_app.running = true
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
                    console.info("exec->onClicked(RIGHT) -> " + actionr)
                    Quickshell.execDetached(actionr);
                    break;

                case Qt.LeftButton:
                    if( actionl == "" ) return;
                    console.info("exec->onClicked(LEFT) -> " + actionl)
                    Quickshell.execDetached(actionl);
                    break;

                case Qt.MiddleButton:
                    if( actionm == "" ) return;
                    console.info("exec->onClicked(MIDDLE)");
                    Quickshell.execDetached(actionm);
                    break;

            }

            if( root.exec_target.length ) exec_app.running = true
        }
    }
}

