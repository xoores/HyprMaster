import Quickshell.Io
import QtQuick

import "ApplicationIcons.js" as AppIcons

JsonObject {
    id: root

    property var app_icons: Object.assign({}, AppIcons.APP_ICONS)
    property var workspace_icons: []

    function get_workspace_icon( ws_id: int ): string {
        for ( const a of root.workspace_icons ) {
            if ( ws_id == a.id ) return a.icon
        }

        return ""
    }

    function get_app_icon( app_class: string ): string {
        const icon = root.app_icons[app_class]
        if ( icon !== undefined ) return icon

        console.warn("Window class without an icon: '" + app_class + "'")
        return root.app_icons["_default"] ?? "?"
    }


    function parse_config( cfg ) {
        if( !cfg ) return
        console.log(`CFG[ICONS]: Loading`)

        // Load icons...

        const apps = Object.assign({}, AppIcons.APP_ICONS)
        for ( const a of cfg?.app_icons ?? [] ) {
            //console.log( "ICON[" +  a.class + "]='" + a.icon + "'" )
            apps[a.class] = a.icon
        }
        root.app_icons = apps

        for ( const a of cfg?.workspace_icons )  {
            //console.log( "WS-ICON[" +  a.id + "]='" + a.icon + "'" )
            root.workspace_icons.push( { id: a.id, icon: a.icon } )
        }
    }

}
