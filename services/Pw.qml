pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

import "../components"
import "../config"

Singleton
{
    id: root
    reloadableId: "volume"

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource

    property int volume_max: 100
    property int volume: sink?.audio?.volume*volume_max
    property bool muted: sink?.audio?.muted ?? false
    property bool mic_muted: source?.audio?.muted ?? false
    property bool mic_in_use: false
    readonly property int change_step: volume < 30 ? 2 : 5


    onSinkChanged: console.info("PwSvc: sink=" + sink?.name)
    onSourceChanged: console.info("PwSvc: source=" + source?.name)

    // Bind the pipewire node so its volume will be tracked
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
    }


    // Normalized value of volume in % (0-100)
    signal sinkVolumeChanged(volume: int, muted: bool, icon: string);
    signal sourceVolumeChanged(volume: int, muted: bool, icon: string);

    Connections {
        target: Pipewire?.defaultAudioSource?.audio

        function onMutedChanged() {
            root.mic_muted = root.source.audio.muted
            root.sourceVolumeChanged( 0, root.mic_muted, root.get_mic_icon())
        }
    }

    Connections {
        target: Pipewire.links
        ignoreUnknownSignals: true

        function is_mic_used(): bool {
            for ( const n of Pipewire.links.values ) {
                if( n.source.isSink ) continue
                root.mic_in_use = true
                return
            }

            root.mic_in_use = false
        }

        function onRowsInserted() {
            is_mic_used()
        }

        function onRowsRemoved() {
            is_mic_used()
        }
    }

    Connections {
        target: Pipewire?.defaultAudioSink?.audio

        function onVolumeChanged() {
            root.volume = root.sink.audio.volume*root.volume_max
            root.sinkVolumeChanged( root.volume, root.muted, root.get_icon())

        }
        function onMutedChanged() {
            root.muted = root.sink.audio.muted
            root.sinkVolumeChanged( root.volume, root.muted, root.get_icon())
        }
    }

    function get_icon(): string {
        const icons = ["", "", ""];

        if( root.sink?.audio?.muted ) return "";

        if( root.volume < 0 || root.volume >= (root.volume_max*0.85) ) return icons[icons.length-1];

        const icon_id = Math.floor(root.volume*(icons.length/root.volume_max));

        //console.debug("monitor_brightness=" + root.volume + "  icon_id=" + icon_id + "/" + x)
        return icons[icon_id];
    }

    function get_mic_icon(): string {
        if( root?.source?.audio.muted ) return "󰍭";
        if( root.mic_in_use ) return "󰍬 ";
        return "󰍬"
    }

    function get_mic_color(): string {
        if( root?.source?.audio.muted ) return Config.appearance.color_fg_disabled
        return Config.appearance.color_fg
    }

    function set(level: int): void {
        if( level < 0 || level > root.volume_max ) {
            console.error("PwSvc: set(" + level + ") failed, invalid value")
            return;
        }

        if( level == root.volume ) return;

        //console.debug("PwSvc: set(" + level + ") for " + sink.name)

        root.volume = level;
        //root.sink.audio.volume = root.volume/root.volume_max
        Quickshell.execDetached(["wpctl", "set-volume", root.sink.id, (level / root.volume_max)])
    }

    function toggle(): void {
        sink.audio.muted = !sink.audio.muted
    }

    function micToggle(): void {
        source.audio.muted = !source.audio.muted
    }

    function is_muted(): bool {
        return sink.audio.muted
    }

    function increase(): void {
        let target = root.volume + root.change_step
        if( target > root.volume_max ) target=root.volume_max;
        set(target)
    }

    function decrease(): void {
        let target = root.volume - root.change_step
        if( target < 1 ) target=1;
        set(target)
    }

    IpcHandler {
        target: "volume"
        function increase() { onPressed: root.increase() }
        function decrease() { onPressed: root.decrease() }
        function toggle() { onPressed: root.toggle() }
        function mic_toggle() { onPressed: root.micToggle() }
    }

}
