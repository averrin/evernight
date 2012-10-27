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


Meteor.startup(->
    if root.Meteor.is_client

        root.Template.login.events = "keyup input": (ev)->
            if ev.keyCode is 13
                root.login()


        fragment = Meteor.render(->
            if Meteor.user()
                Template.main()
            else
                Template.login()
        )
        $("#content").html fragment
        console.log 'Hello Evernight'
)
