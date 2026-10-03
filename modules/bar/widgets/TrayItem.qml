pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls

import "../../../components"
import "../../../config"
import "../../../services"


MouseArea {
    id: root
    required property SystemTrayItem modelData
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    implicitWidth: 16
    implicitHeight: 16

    //cursorShape: Qt.PointingHandCursor

    onClicked: event => {
        if (event.button === Qt.LeftButton) {
            root.modelData.activate();

        } else {
            if (root.modelData.hasMenu) {
                menuAnchor.open();
            } else {
                root.modelData.secondaryActivate();
            }
        }
    }

    function iconCandidates(spec: string): var {
        const prefix = "image://icon/";

        if (!spec)
            return [];

        if (!spec.startsWith(prefix))
            return [spec];

        let id = spec.substring(prefix.length);
        let path = "";

        const pathIdx = id.indexOf("?path=");
        if (pathIdx !== -1) {
            path = id.substring(pathIdx + 6);
            id = id.substring(0, pathIdx);
        }

        const name = id.substring(id.lastIndexOf("/") + 1);
        const candidates = [];

        if (path) {
            for (const ext of ["png", "svg", "xpm"])
                candidates.push("file://" + path + "/" + name + "." + ext);
            candidates.push("file://" + path + "/" + name);
        }

        // Intentionally push "non-resolveable" icon so the QS falls back to the black/magenta placeholder
        candidates.push(prefix + name);
        return candidates;
    }

    QsMenuAnchor {
        id: menuAnchor
        menu: root.modelData?.menu
        anchor.window: window
        anchor.rect: window.mapFromItem(root, 0, root.height, root.width, root.width)
    }

    IconImage {
        id: icon
        asynchronous: true
        anchors.fill: parent
        visible: status === Image.Ready
        mipmap: true
        backer.smooth: true

        readonly property var candidates: root.iconCandidates(root.modelData?.icon ?? "")
        property int candidateIndex: 0

        source: candidates[candidateIndex] ?? ""

        onCandidatesChanged: candidateIndex = 0

        onStatusChanged: {
            if (status !== Image.Error)
                return;

            if (candidateIndex < candidates.length - 1) {
                candidateIndex += 1;
            } else {
                console.warn("Tray[" + root.modelData?.id + "]: no usable icon for '" + root.modelData?.icon + "'");
            }
        }
    }

    StyledTooltip {
        anchorItem: root
        text: (root.modelData.tooltipTitle || root.modelData.title || root.modelData.tooltipDescription || "")
    }
}
