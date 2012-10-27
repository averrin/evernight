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
        root.Template.main.events =
            "click #logout": (ev)->
                Meteor.logout()

        root.Template.main.rendered = ->
            if Meteor.user()
                $('#content').addClass 'main'

        root.Template.login.rendered = ->
            $('#content').removeClass 'main'

        root.Template.menu.events =
            "click #logout_link": (ev)->
                ev.preventDefault()
                Meteor.logout()


        fragment = Meteor.render(->
            if Meteor.user()
                Template.main()
            else
                Template.login()
        )
        $("#content").html fragment

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
)
