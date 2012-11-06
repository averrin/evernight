root = global ? window

root.login = ->
    counter = 0
    $('#login input').each (i,e)->
        if not $(e).val()
            $(e).addClass 'error'
        else
            $(e).removeClass 'error'
            counter++
    if counter is $('#login input').length
        Meteor.loginWithPassword $('#login_input').val(),
            $('#password_input').val(),
            (error)->
                if error
                    root.dialog 'err', 'Login error', error.reason
                else
                    console.log "signed in"
                    root.controller.navigate location.hash.split('#')[1], trigger: true

root.init_users = ->
    root.Accounts.createUser({username:'averrin',email:'averrin@gmail.com',password:'owertryn8',profile:{name:'Averrin'}})
    root.Accounts.createUser({username:'a',email:'a@gmail.com',password:'a',profile:{name:'Averrin'}})

root.dialog = (id, title, content)->
    d = root.Template.modal
        id: id
        title: title
        content: content
    $('body').append d
    $('#'+id).reveal()

root.add_ip = ->
    counter = 0
    $('#new_ip input').each (i,e)->
        if not $(e).val()
            $(e).addClass 'error'
        else
            $(e).removeClass 'error'
            counter++
    if counter is $('#new_ip input').length
        root.IPs.insert
            ip: $('#address').val()
            name: $('#title').val()
            owner: root.Meteor.user()._id
        $('#new_ip input').each (i,e)->
            $(e).val ''

root.load_fragment = (render)->
    fragment = Meteor.render(->
        if Meteor.user()
            render()
        else
            Template.login()
    )
    $('#content').html fragment


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
    "color": 156,

root.update_serverlist = ->
    $('.reveal-modal').trigger 'reveal:close'
    ss = Session.get 'servers'
    Session.set 'servers', ''
    Session.set 'servers', ss

Meteor.startup(->


    root.IPs  = new root.Meteor.Collection("IPs")
    root.SERVERS  = new root.Meteor.Collection("SERVERS")

    if root.Meteor.is_client
        root.Handlebars.registerHelper 'each_with_index', (array, obj) ->
            ret = ''
            _.each array, (e, i) ->
                r = obj.fn(i + ': ' + e)
                ret += r
            ret

        root.Handlebars.registerHelper 'noEscape', (arg) ->
            new Handlebars.SafeString arg


        root.Template.login.events = "keyup input": (ev)->
            if ev.keyCode is 13
                root.login()
        root.Template.main.events =
            "click #logout": (ev)->
                root.controller.navigate '!/logout', trigger: true
            "click .del_ip": (ev)->
                ev.preventDefault()
                root.IPs.remove(this._id)
            "keyup input": (ev)->
                if ev.keyCode is 13
                    root.add_ip()

        root.Template.servers.events =
            "click .view_server": (ev)->
                ev.preventDefault()
                root.dialog 'view_server', this.alias, '<pre class="prettyprint lang-js for_modal">'+JSON.stringify(this, undefined, 4)+'</pre>'
                prettyPrint()
            "click .edit_server": (ev)->
                ev.preventDefault()
                id = this._id
                root.dialog 'edit_server_'+id, this.alias, '<div id="server_editor"> <button class="right save_server" style="margin-top: 6px;" data-uuid="'+id+'">Save</button> </div>'
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#edit_server_'+id+" #server_editor").prepend elt
                ,
                    value: JSON.stringify(this, `undefined`, 4)
                    mode: "javascript"
                    theme: "ambiance"
                    indentUnit: 4
                )
                $('.save_server').click (ev)->
                    ev.preventDefault()
                    id = root.SERVERS.findOne _id: $(this).attr 'data-uuid'
                    console.log id
                    root.SERVERS.update id, $.parseJSON(myCodeMirror.getValue())
                    root.update_serverlist()
            "click .add_server": (ev)->
                ev.preventDefault()
                console.log 'add server'
                root.dialog 'add_server', 'New server', '<div id="server_editor"><button class="right save_new_server" style="margin-top: 6px;">Save</button> </div>'
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#add_server #server_editor').prepend elt
                ,
                    value: JSON.stringify(root.server_template, `undefined`, 4)
                    mode: "javascript"
                    theme: "ambiance"
                    indentUnit: 4
                )
                $(".save_new_server").click (ev)->
                    ev.preventDefault()
                    server = $.parseJSON(myCodeMirror.getValue())
                    server['owner'] = Meteor.user()._id
                    root.SERVERS.insert server
                    root.update_serverlist()
            "click .del_server": (ev)->
                ev.preventDefault()
                root.SERVERS.remove this._id
                root.update_serverlist()

            "click .tags span": (ev)->
                q = root.visualSearch.searchBox.value() + ' tags: ' + this
                root.visualSearch.searchBox.value(q)
                root.visualSearch.options.callbacks.search(q, root.visualSearch.searchQuery)
            "click .groups span": (ev)->
                q = root.visualSearch.searchBox.value() + ' groups: ' + this
                root.visualSearch.searchBox.value(q)
                root.visualSearch.options.callbacks.search(q, root.visualSearch.searchQuery)


#        root.Template.servers.preserve ['.visual_search']

        root.Template.servers_list.servers_list = ->
            Session.get 'servers_list'

        root.Template.main.rendered = ->
            prettyPrint()

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
                        Session.set 'servers_list', root.SERVERS.find(q, {sort: {alias:1}}).fetch()
                        # root.visualSearch.searchBox.value(query)

                    facetMatches: (callback) ->
                        callback ['ip', 'host', 'tags', 'groups', 'alias']

                    valueMatches: (facet, searchTerm, callback) ->
                        ss = root.SERVERS.find(owner: Meteor.user()._id).fetch()
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
            )
            visualSearch = root.visualSearch
            root.visualSearch.searchBox.value Session.get 'q'
            Session.set 'q', ''

        root.Template.login.rendered = ->
            $('#content').removeClass 'main'

        root.Template.menu.events =
            "click #logout_link": (ev)->
                ev.preventDefault()
                Meteor.logout()


        menu = Meteor.render(->
            if Meteor.user()
                Template.menu()
            else
                ''
        )
        $('header').append(menu)
        sidebar = Meteor.render(->
            if Meteor.user()
                Template.sidebar()
            else
                ''
        )
        $('.side').append(sidebar)

        console.log 'Hello Evernight'

        if Meteor.user()
            if Meteor.user()
                console.log 'Hello, user'

        $('.logo').click ->
            window.location.reload()

        root.Controller = root.Backbone.Router.extend
            routes:
                "": 'reset'
                "!/ips": 'ips'
                "!/logout": "logout"
                "!/servers": "servers"
            reset: ->
                $('title').html ':main'
                root.load_fragment ->
                    Template.main()
            logout: ->
                Meteor.logout()
            ips: ->
                $('title').html ':ips'
                root.load_fragment ->
                    Template.ips ips: root.IPs.find(owner: Meteor.user()._id)
            servers: ->
                $('title').html ':servers'
                root.load_fragment ->
                    if Meteor.user()
                        Session.set 'servers_list', root.SERVERS.find({owner: Meteor.user()._id}, {sort: {alias:1}}).fetch()
                        Template.servers()

        root.controller = new root.Controller
        root.Backbone.history.start()

        root.controller.navigate location.hash.split('#')[1], trigger: true

)

# IPs.insert({'ip':'10.137.190.187','name':'localhost','owner':Meteor.user()._id})
