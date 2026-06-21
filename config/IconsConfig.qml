import Quickshell.Io
import QtQuick

JsonObject {
    id: root

    property var app_icons: []
    property var workspace_icons: []

    function get_workspace_icon( ws_id: int ): string {
        for ( const a of root.workspace_icons ) {
            if ( ws_id == a.id ) return a.icon
        }

        return ""
    }

    function get_app_icon( app_class: string ): string {
        var icon="?"

        // Try looking up icon - save "default" one in the first loop
        // so we don't have to iterate twice.
        for ( const a of root.app_icons ) {
            if ( app_class == a.class ) return a.icon
            if ( a.class == "_default" ) icon=a.icon
        }

        console.warn("Window class without an icon: '" + app_class + "'")
        return icon
    }


    function parse_config( cfg ) {
        if( !cfg ) return
        console.log(`CFG[ICONS]: Loading`)


        // Load icons...
        for ( const a of cfg?.app_icons ) {
            //console.log( "ICON[" +  a.class + "]='" + a.icon + "'" )
            root.app_icons.push( { class: a.class, icon: a.icon } )
        }

        for ( const a of cfg?.workspace_icons )  {
            //console.log( "WS-ICON[" +  a.id + "]='" + a.icon + "'" )
            root.workspace_icons.push( { id: a.id, icon: a.icon } )
        }
    }

}
