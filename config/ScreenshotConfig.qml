import Quickshell.Io
import QtQuick

JsonObject {
    id: root

    property string video_target: "$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
    property string image_target: "$HOME/Pictures/screenshot/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

    property string satty_parameters: " --resize --early-exit " +
                                        "--output-filename \"" + image_target + "\" " +
                                        "--actions-on-enter save-to-clipboard " +
                                        "--save-after-copy " +
                                        "--copy-command 'wl-copy'"

    property string wfrecorder_parameters: "-f  \""+ video_target +"\""

    function parse_config( cfg ) {
        if( !cfg ) return
        console.log(`CFG[SCREENSHOT]: Loading`)

        for( const c in cfg ) {
            if( c === "#" ) continue
            console.log(`CFG[SCREENSHOT]: '${c}' = '${cfg[c]}'`)
            Config._assignValue(cfg[c], root[c])
        }
    }

}
