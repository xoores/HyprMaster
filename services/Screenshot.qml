pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io

import "../components"
import "../config"


Singleton {
    id: root

    property bool isRecording: false

    property bool   _active: false
    property bool   _freeze: true
    property bool   _actionRecording: false

    // Recording region — used by the red border overlay
    property var  _recordingScreen: null
    property real _recordingLocalX: 0
    property real _recordingLocalY: 0
    property real _recordingW:      0
    property real _recordingH:      0

    function takeScreenshot(freeze: bool) {
        _actionRecording = false
        _freeze = freeze ?? true
        _active = true
    }

    function startRecording() {
        if (isRecording) return
        _actionRecording = true
        _freeze = false
        _active = true
    }

    function stopRecording() {
        recorderProcess.running = false
    }

    // video recording process
    Process {
        id: recorderProcess
        running: false
        onExited: {
            root.isRecording = false
            root._recordingScreen = null
        }
    }

    ScreenpickerOverlay {
        freeze: root._freeze
        actionRecording: root._actionRecording
        active: root._active

        onSelectedRegion: (globalX, globalY, w, h, screen, localX, localY, directlyToClipboard) => {
            root._active = false
            const geo = `${Math.round(globalX)},${Math.round(globalY)} ${Math.round(w)}x${Math.round(h)}`

            if ( root._actionRecording ) {
                root._recordingScreen = screen
                root._recordingLocalX = localX
                root._recordingLocalY = localY
                root._recordingW      = w
                root._recordingH      = h
                recorderProcess.command = [ "bash", "-c", `wf-recorder -g "${geo}" ${Config.screenshot.wfrecorder_parameters}` ]
                console.log("SCROT-CMD[VIDEO]: " + recorderProcess.command)
                recorderProcess.running = true
                root.isRecording = true

            } else {
                var command = "";

                // directlyToClipboard => skip satty & send image directly to clipboard (shortcut)
                if( directlyToClipboard ) {
                    command = ["bash", "-c", `grim -g "${geo}" - | wl-copy -t image/png`]

                } else {
                    command = ["bash", "-c", `grim -g "${geo}" - | satty --filename - ${Config.screenshot.satty_parameters}`]
                }

                console.log("SCROT-CMD[IMAGE]: " + command)
                Quickshell.execDetached(command)
            }
        }

        onSelectedMonitor: (screenName) => {
            root._active = false
            const command = ["bash", "-c", `grim -o "${screenName}" - | satty --filename - ${Config.screenshot.satty_parameters}`]
            console.log("SCROT-CMD[MONITOR]: " + command)
            Quickshell.execDetached(command)
        }

        onCancelled:  root._active = false
    }

    ScreenrecordOverlay { }
}