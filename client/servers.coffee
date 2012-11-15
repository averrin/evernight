root = global ? window

root.server_template =
    "description": "Local server",
    "tags": [],
    "ssh_port": 22,
    "ip": "127.0.0.1",
    "host": "localhost",
    "groups": [],
    "projects": [],
    "ftp_port": 21,
    "other_hosts": [],
    "alias": "localhost",
    "ssh_user": "",
    "ssh_password": "",
    "ssh_cert": "",
    "os": "linux",
    "color": 156

root.update_servers = ->
    $('.reveal-modal').trigger 'reveal:close'
    root.visualSearch.options.callbacks.search(Session.get('q'), root.visualSearch.searchQuery)
    
    
   
root.compile_config = (config_name, server)->
    if server.aliases
        _.each root.ALIASES.find().fetch(), (e,i)->
            if _.pluck(server.aliases, 'a').indexOf(e.a) == -1
                server.aliases.push e
    else
        server.aliases = root.ALIASES.find().fetch()
    Mustache.render(CONFIGS.findOne(title: config_name).content, server)


Meteor.startup(->
    if root.Meteor.is_client
    
        root.Template.servers.events =
            "click .view_server": (ev)->
                ev.preventDefault()
                root.dialog 'view_server', this.alias, '<pre class="prettyprint lang-js for_modal">'+JSON.stringify(this, undefined, 4)+'</pre>'
                prettyPrint()
            "click .edit_server": (ev)->
                ev.preventDefault()
                id = this._id
                $('#edit_server_'+id).remove()
                root.dialog 'edit_server_'+id, this.alias, '<div id="server_editor"> <button class="right save_server" style="margin-top: 6px;" data-uuid="'+id+'">Save</button> </div>'
                content = {}
                _.each this, (e,i)->
                    if _.indexOf(['owner', '_id'], i) == -1
                        content[i] = e
                root.cm_config.value = JSON.stringify(content, `undefined`, 4)
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#edit_server_'+id+" #server_editor").prepend elt
                ,
                    root.cm_config
                )
                $('.save_server').click (ev)->
                    ev.preventDefault()
                    try
                        content = $.parseJSON(myCodeMirror.getValue())
                        root.SERVERS.update {_id: $(ev.target).attr('data-uuid')}, {$set: content}
                        root.update_servers()
                    catch error
                        myCodeMirror.openDialog root.json_error
            "click .add_server": (ev)->
                ev.preventDefault()
                console.log 'add server'
                $("#add_server").remove()
                root.dialog 'add_server', 'New server', '<div id="server_editor"><button class="right save_new_server" style="margin-top: 6px;">Save</button> </div>'
                root.cm_config.value = JSON.stringify(root.server_template, `undefined`, 4)
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#add_server #server_editor').prepend elt
                ,
                    root.cm_config
                )
                $(".save_new_server").click (ev)->
                    ev.preventDefault()
                    try
                        server = $.parseJSON(myCodeMirror.getValue())
                        server['owner'] = Meteor.user()._id
                        root.SERVERS.insert server
                        root.update_servers()
                    catch error
                        myCodeMirror.openDialog root.json_error
            "click .del_server": (ev)->
                ev.preventDefault()
                root.SERVERS.remove this._id
                root.update_servers()
                
            "click .view_config": (ev)->
                ev.preventDefault()
                $("#view_config").remove()
                config_select = '<select id="config_title">'
                _.each CONFIGS.find().fetch(), (e,i)->
                    config_select += '<option value="' + e.title + '">' + e.title + '</option>'
                config_select += '</select>'
                root.dialog 'view_config', 'View configs',
                    config_select + '
                    <div id="config_editor">
                    </div>'
                $('#config_title').chosen()
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#view_config #config_editor').prepend elt
                ,
                    value: root.compile_config($('#config_title').val(), this)
                    mode: "javascript"
                    theme: "ambiance"
                    indentUnit: 4
                )
                $('#config_title').change (ev)->
                    title = $(this).val()
                    root.myCodeMirror.setValue root.compile_config($('#config_title').val(), this)

            "click .tags span": (ev)->
                q = root.visualSearch.searchBox.value() + ' tags: ' + this
                root.visualSearch.searchBox.value(q)
                root.visualSearch.options.callbacks.search(q, root.visualSearch.searchQuery)

            "click .groups span": (ev)->
                q = root.visualSearch.searchBox.value() + ' groups: ' + this
                root.visualSearch.searchBox.value(q)
                root.visualSearch.options.callbacks.search(q, root.visualSearch.searchQuery)

        root.Template.servers_list.servers_list = ->
            ss = Session.get 'servers'
            if ss
                return ss
            else
                root.SERVERS.find({}, {sort: {alias:1}}).fetch()
            

        root.Template.servers.rendered = ->
            root.visualSearch = VS.init(
                container: $(".visual_search")
                query: ""
                callbacks:
                    search: (query, searchCollection) ->
                        root.q = searchCollection
                        q = {}
                        _.each root.q.facets(), (e,i)->
                            _.each e, (e,i)->
                                if i is 'host'
                                    q['$or'] = [{'host':e},{'other_hosts':e}]
                                else
                                    q[i] = e
                        q['owner'] = Meteor.user()._id
                        Session.set 'q', query
                        Session.set 'servers', ''
                        Session.set 'servers', root.SERVERS.find(q, {sort: {alias:1}}).fetch()
                        

                    facetMatches: (callback) ->
                        callback ['ip', 'host', 'tags', 'groups', 'alias', 'os']

                    valueMatches: (facet, searchTerm, callback) ->
                        ss = root.SERVERS.find().fetch()
                        switch facet
                            when "alias"
                                r = []
                                _.each ss, (e,i)->
                                    r.push e.alias
                                callback r
                            when "ip"
                                r = []
                                _.each ss, (e,i)->
                                    r.push e.ip
                                callback r
                            when "host"
                                r = []
                                _.each ss, (e,i)->
                                    r.push e.host if e.host != ""
                                    _.each e.other_hosts, (e,i)->
                                        if e != "" && _.indexOf(r, e) == -1
                                            r.push e
                                callback r
                            when "tags"
                                r = []
                                _.each ss, (e,i)->
                                    _.each e.tags, (e,i)->
                                        if e != "" && _.indexOf(r, e) == -1
                                            r.push e
                                callback r
                            when "groups"
                                r = []
                                _.each ss, (e,i)->
                                    _.each e.groups, (e,i)->
                                        if e != "" && _.indexOf(r, e) == -1
                                            r.push e
                                callback r
                            when "os"
                                callback ["linux", "windows"]
            )
            visualSearch = root.visualSearch
            root.visualSearch.searchBox.value Session.get 'q'
            
)
