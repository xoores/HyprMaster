import Quickshell.Io
import QtQuick

JsonObject {
    id: root

    property string color_bg: "#88000000"
    property string color_bg_dark: "#ff000000"
    property string color_bg_accent: "#55ffffff"


    property string color_accent_active: "white"
    property string color_accent_inactive: "#285577"

    property string color_primary_active: "#285577"
    property string color_primary_error: "#77282a"
    property string color_primary_disabled: "#727272"
    property string color_primary_inactive: "#4c7899"


    // Used in: texts, labels
    property string color_fg: "#cdd6f4"

    // Used in: inactive devices (network, bt...)
    property string color_fg_disabled: "gray"


    property string color_fg_good: "#00FF00"
    property string color_fg_warning: "yellow"
    property string color_fg_error: "#FF0000"

    property alias color_fg_active: root.color_fg_good

    property int bar_height: 24

    property int font_size: 16

    property string font_family: "Mononoki Nerd Font Propo"
    property string font_family_material: "Material Icons Sharp"

    property int radius: 12


    function parse_config( cfg ) {
        if( !cfg ) return
        console.log(`CFG[APPEARANCE]: Loading`)

        for( const c in cfg ) {
            if( c === "#" ) continue
            console.log(`CFG[APPEARANCE]: '${c}' = '${cfg[c]}'`)
            Config._assignValue(cfg[c], root[c])
        }
    }

}
