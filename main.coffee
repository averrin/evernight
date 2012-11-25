###
    TODO:
        * CodeMirror editor creation method
        * Edit collection dialog (maybe to sidebar)
        * Refactor less
###

root = global ? window

root.online = ->
    console.log 'online'

root.offline = ->
    console.log 'offline'

root.toggle_sidebar = ->
    if not root.right.isOpen
        root.right.open '500', ->
            console.log root.right
    else
        root.right.close '500', ->
            console.log root.right

root.ping = (ip, online, offline) ->
    _that = this
    @good = online
    @bad = offline
    @ans = false
    @ip = ip
    @img = new Image()
    @img.onload = ->
        if not _that.ans
            _that.ans = true
            _that.good()

    @img.onerror = ->
        if not _that.ans
            _that.ans = true
            _that.good()

    @start = new Date().getTime()
    @img.src = "http://" + _that.ip
    @timer = setTimeout(->
        if not _that.ans
            _that.ans = true
            _that.bad()
    , 1500)

root.json_error = '<div class="alert alert-error">
                    <button type="button" class="close" data-dismiss="alert">&#215;</button>
                    <strong>Error!</strong> Bad JSON format!</div>'


root.edit_collection = (collection, filtered)->
    if not filtered
        _coll = collection.find(owner: Meteor.user()._id).fetch()
        coll = []
        _.each _coll, (e,i)->
            delete e._id
            delete e.owner
            coll.push e
    else
        coll = collection
    $('#edit_collection').remove()
    root.dialog 'edit_collection', 'Edit collection',
        '<div id="collection_editor">
            <button class="right save_collection" style="margin-top: 6px;">Save</button>
        </div>'
    root.cm_config.value = JSON.stringify(coll, `undefined`, 4)
    root.myCodeMirror = root.CodeMirror((elt) ->
            $('#edit_collection #collection_editor').prepend elt
        ,
            root.cm_config
        )


    if not filtered
        $(".save_collection").click (ev)->
            ev.preventDefault()
            try
                new_coll = $.parseJSON(myCodeMirror.getValue())
                collection.remove({owner: Meteor.user()._id})
                _.each new_coll, (e,i)->
                    e.owner = Meteor.user()._id
                    collection.insert e
                $('.reveal-modal').trigger 'reveal:close'
                console.log 'TODO: save collection without recreate'
            catch error
                myCodeMirror.openDialog root.json_error
    else
        $(".save_collection").click (ev)->
            ev.preventDefault()
            try
                Meteor.users.update({_id: Meteor.user()._id}, {$set: {profile: $.parseJSON(myCodeMirror.getValue())}})
                $('.reveal-modal').trigger 'reveal:close'
            catch error
                myCodeMirror.openDialog root.json_error



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
                    h = location.hash.split('#')[1]
                    if h
                        root.controller.navigate h, trigger: true

root.init_users = ->
    root.Accounts.createUser({username:'a',email:'a@gmail.com',password:'a',profile:{name:'Averrin'}})



root.dialog = (id, title, content)->
    d = root.Template.modal
        id: id
        title: title
        content: content
    $('body').append d
    $('#'+id).reveal()


root.pr = ->
    root.h = location.hash.split('#')[1]
    k = root.controller.routes[root.h]
    root.controller[k]()
    console.log 'process hash', root.h
    root.controller.navigate root.h, true

Meteor.startup(->

    root.SERVERS  = new root.Meteor.Collection("SERVERS")

    root.CONFIGS  = new root.Meteor.Collection("CONFIGS")

    root.ALIASES  = new root.Meteor.Collection("ALIASES")

    root.KEYS  = new root.Meteor.Collection("KEYS")

    root.PROJECTS  = new root.Meteor.Collection("PROJECTS")

    root.TABS  = new root.Meteor.Collection("TABS")

    root.collections =
        'Servers': root.SERVERS
        'Configs': root.CONFIGS
        'Aliases': root.ALIASES
        'Keys': root.KEYS
        'Projects': root.PROJECTS
        'Tabs': root.TABS

    if root.Meteor.is_server

        _.each root.collections, (e,i)->

            Meteor.publish '', ->
                e.find(owner: this.userId)

            e.allow
                insert: (userId, doc) ->
                    userId and doc.owner is userId

                update: (userId, docs, fields, modifier) ->
                    _.all docs, (doc) ->
                        doc.owner is userId


                remove: (userId, docs) ->
                    _.all docs, (doc) ->
                        doc.owner is userId

                fetch: ["owner"]


        root.collectionApi = new root.CollectionAPI( authToken: '3d714fb7-a389-4748-a781-2f9329fbc280')
        root.collectionApi.addCollection(root.SERVERS, 'SERVERS')
        root.collectionApi.addCollection(root.KEYS, 'KEYS')
        root.collectionApi.addCollection(root.KEYS, 'PROJECTS')
        root.collectionApi.addCollection(Meteor.users, 'PROFILES')
        root.collectionApi.start()

    root.Meteor.methods
        upload_servers: ->
            fs = __meteor_bootstrap__.require("fs")
            path = __meteor_bootstrap__.require("path")
            base = path.resolve(".")
            data = fs.readFileSync(path.join(base, "/server/", 'servers.json'), 'utf8')
            servers = JSON.parse data
            Object.keys(servers).forEach (i)->
                e = servers[i]
                e['alias'] = i
                SERVERS.insert e
            console.log 'uploaded'

        backup_servers: ->
            fs = __meteor_bootstrap__.require("fs")
            path = __meteor_bootstrap__.require("path")
            base = path.resolve(".")
            data = {}
            SERVERS.find().fetch().forEach (e)->
                data[e.alias] = e
            data = fs.writeFileSync(path.join(base, "/server/", 'servers.json'), JSON.stringify(data), 'utf8')
            console.log 'backed up'

    if root.Meteor.is_client

        root.Template.body.rendered = ->
            if window.location.hostname is 'en.averr.in'
                if not $('.title:first').html().match(/.*\[dev\]/)
                    $('.title:first').append '[dev]'

            root.right.show()

        _.each root.shortcuts, (e,i)->
            root.Mousetrap.bind e.key, e.func


        root.Mousetrap.bind "?", ->
            root.dialog 'help', 'Help', root.Mustache.render('
                <h3>:keys</h3>
                <ul>{{#shortcuts}}
                    <li><strong>&lt;{{key}}&gt;</strong>&nbsp;&mdash;&nbsp;{{desc}}</li>
                {{/shortcuts}}</ul>', shortcuts: root.shortcuts)


        $('.tab_header').live 'click', (ev)->
            ev.preventDefault()
            h = $(ev.target).data('hash')
            console.log h
            Session.set 'page', h

        root.Template.main.placeholder = ->
            user = Meteor.users.findOne({_id: Meteor.user()._id})
            if user and user.profile.lorem
                return root.Mustache.render(user.profile.placeholder, user.profile)
            else
                'Lorem ipsum'

        $('body').append Meteor.render(->
            Template.body()
        )

        #Session.set 'collections', Meteor.users.findOne({_id: Meteor.user()._id}).profile.collections
        root.Template.sidebar.collections = ->
            user = Meteor.users.findOne({_id: Meteor.user()._id})
            if user
                return user.profile.collections
            else
                []



        root.foldFunc = root.CodeMirror.newFoldFunction root.CodeMirror.braceRangeFinder
        root.cm_config =
            mode: "mustache"
            theme: "ambiance"
            indentUnit: 4
            lineWrapping: true
            lineNumbers: true
            matchBrackets: true
            onGutterClick: root.foldFunc
            extraKeys:
                "Ctrl-Q": (cm)->
                    root.foldFunc cm, cm.getCursor().line
                "Ctrl-S": (cm)->
                    $('.reveal-content button').click()

        root.Template.sidebar.events =
            "click .edit_collection": (ev)->
                ev.preventDefault()
                key = $(ev.target).attr('data-collection')
                root.edit_collection(root.collections[key])
            "mouseenter .side>.inverted": (ev)->
                console.log ev.target
                $(ev.target).toggleClass 'hovered'

            "click .edit_profile": (ev)->
                ev.preventDefault()
                root.edit_collection Meteor.user().profile, true

            "click .hide_sidebar": (ev)->
                ev.preventDefault()
                root.toggle_sidebar()



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

        $('.logo').click ->
            window.location.reload()

        root.Template.main.rendered = ->
            prettyPrint()
            $("#placeholder").contentEditable().change (e)->
                if e.action is 'save'
                    data = Meteor.user().profile
                    data.placeholder = $('<div/>').html($('#placeholder div').html().replace('<br>', '&lt;br&gt;')).text()
                    Meteor.users.update({_id: Meteor.user()._id}, {$set: {profile: data}})


        root.Template.two_columns.page = ->
            tpl = Session.get 'page'
            tab = root.TABS.findOne hash: tpl
            if tab
                if _.indexOf(_.keys(tab), 'content') != -1
                    tpl = Mustache.render(tab.content, Meteor.users.findOne({_id: Meteor.user()._id}).profile)
                else
                    tpl = 'Empty tab'
            else
                tpl = root.Template[tpl]()
            # tpl = root.Meteor.render ->
                # tpl()

            # return $('<div></div>').html(tpl).html()
            return tpl

        root.Template.two_columns.tabs = ->
            pre = [
                title: ':main'
                hash: 'main'
            ]
            _.each root.TABS.find().fetch(), (e,i)->
                pre.push e
            return pre

        root.Template.two_columns.rendered = ->
            $('.tab_header[data-hash="'+Session.get('page')+'"]').addClass 'active'


        root.Template.menu.events =
            "click #logout_link": (ev)->
                ev.preventDefault()
                Meteor.logout()


        root.Controller = root.Backbone.Router.extend
            routes:
                "": 'reset'
                "!/:page": 'reset'
                "!/logout": "logout"
                #"!/servers": "servers"
            reset: (page)->
                if page
                    Session.set 'page', page
                else
                    Session.set 'page', 'main'
            logout: ->
                Meteor.logout()

            servers: ->
                $('title').html ':servers'
                $('#content').html Meteor.render(->
                    if Meteor.user()
                        Template.servers()
                )

        root.controller = new root.Controller
        root.Backbone.history.start()


        $('.aloha-sidebar-inner').html Meteor.render(->
            Template.sidebar()
        )

        console.log "Evernight Init"


)
