root = global ? window

root.shortcuts = [
            "key": "x"
            "desc": "Toggle sidebar"
            "func": ->
                root.toggle_sidebar()
        ,
            "key": "m"
            "desc": "Edit Main collection"
            "func": ->
                root.edit_collection Meteor.user().profile, true
        ,
            "key": "s"
            "desc": "Edit Servers collection"
            "func": ->
                root.edit_collection root.collections['Servers']
        ,
            "key": "c"
            "desc": "Edit Configs collection"
            "func": ->
                root.edit_collection root.collections['Configs']
        ,
            "key": "a"
            "desc": "Edit Aliases collection"
            "func": ->
                root.edit_collection root.collections['Aliases']
        ,
            "key": "k"
            "desc": "Edit Keys collection"
            "func": ->
                root.edit_collection root.collections['Keys']
        ,
            "key": "esc"
            "desc": "Close modal dialog"
            "func": ->
                $('.reveal-modal').trigger 'reveal:close'
        ,
            "key": "/"
            "desc": "Focus Servers search"
            "func": ->
                try
                    visualSearch.searchBox.focusSearch()
                    
        ,
            "key": "S"
            "desc": "Add new server"
            "func": ->
                ev = new Event('')
                root.Template.servers.events["click .add_server"](ev)
        ,
            "key": "C"
            "desc": "Add new config"
            "func": ->
                ev = new Event('')
                root.Template.configs.events["click .add_config"](ev)
                
    ]