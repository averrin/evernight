console.log 'Hello Evernight'

root = global ? window

root.login = ->
    counter = 0
    $('#login input').each (i,e)->
        if not $(e).val()
            $(e).addClass 'error'
        else
            $(e).removeClass 'error'
            counter++
    if counter is 2
        Meteor.loginWithPassword $('#login_input').val(),
            $('#password_input').val(),
            (error)->
                if error
                    alert error.reason
                else
                    root.main_init()

root.main_init = ->
    console.log "load main"
    $("#content").html Template.main()

if root.Meteor.is_client
    root.Template.main.rendered = ->
        console.log "Entered",  Meteor.userLoaded(), Meteor.user()

    root.Template.login.events = "keyup input": (ev)->
        if ev.keyCode is 13
            root.login()

    if Meteor.user()
        console.log "have user", Meteor.user(), Meteor.userLoaded()
        root.main_init()
    else
        console.log 'havent user'
