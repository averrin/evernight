###
    TODO:
        * CodeMirror editor creation method
        * Edit collection dialog (maybe to sidebar)
        * Refactor less
###

root = global ? window

root.edit_collection = (collection)->
    _coll = collection.find(owner: Meteor.user()._id).fetch()
    coll = []
    _.each _coll, (e,i)->
        delete e._id
        delete e.owner
        coll.push e
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
    $(".save_collection").click (ev)->
        ev.preventDefault()
        new_coll = $.parseJSON(myCodeMirror.getValue())
        collection.remove({})
        _.each new_coll, (e,i)->
            e.owner = Meteor.user()._id
            collection.insert e
        $('.reveal-modal').trigger 'reveal:close'
        console.log 'TODO: save collection without recreate'
    
   
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
    
    root.collections =
        'SERVERS': root.SERVERS
        'CONFIGS': root.CONFIGS
        'ALIASES': root.ALIASES
    
    #ALIASES.insert({c:'fab -f ~/nervarin.py', a:'n', owner:Meteor.user()._id})
    #ALIASES.insert({c:'sudo pip install', a:'pipi', owner:Meteor.user()._id})
  
    #if root.Meteor.is_server
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
                console.log key
                root.edit_collection(root.collections[key])
                
        
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


        root.Template.menu.events =
            "click #logout_link": (ev)->
                ev.preventDefault()
                Meteor.logout()

 
        root.Controller = root.Backbone.Router.extend
            routes:
                #"": 'reset'
                "!/logout": "logout"
                #"!/servers": "servers"
            reset: ->
                $('title').html ':main'
                $('#left-content').html Meteor.render(->
                    if Meteor.user()
                        Template.main()
                )
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

        $('body').append Meteor.render(->
            Template.body()
        )
              

)

