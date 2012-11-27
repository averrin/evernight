root = global ? window

Meteor.startup(->
    if root.Meteor.is_client
        root.Template.projects.projects = ->
            root.PROJECTS.find().fetch()

        root.Template.projects.events =
            "click .del_project": (ev)->
                ev.preventDefault()
                console.log 'del project'
                root.PROJECTS.remove this._id

            "click .edit_project": (ev)->
                ev.preventDefault()
                id = this._id
                $('#edit_project_'+id).remove()
                root.dialog 'edit_project_'+id, this.alias, '<div id="project_editor"> <button class="right save_project" style="margin-top: 6px;" data-uuid="'+id+'">Save</button> </div>'
                content = {}
                _.each this, (e,i)->
                    if _.indexOf(['owner', '_id'], i) == -1
                        content[i] = e
                root.cm_config.value = JSON.stringify(content, `undefined`, 4)
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#edit_project_'+id+" #project_editor").prepend elt
                ,
                    root.cm_config
                )
                $('.save_project').click (ev)->
                    ev.preventDefault()
                    try
                        content = $.parseJSON(myCodeMirror.getValue())
                        root.PROJECTS.update {_id: $(ev.target).attr('data-uuid')}, {$set: content}
                        new_serv = root.PROJECTS.findOne {_id: $(ev.target).attr('data-uuid')}
                        _.each new_serv, (e,i)->
                            if _.indexOf(['owner', '_id'], i) == -1
                                if _.indexOf(_.keys(content), i) == -1
                                    mod = {$unset: {}}
                                    mod['$unset'][i] = 1
                                    root.PROJECTS.update {_id: new_serv._id}, mod
                        $('.reveal-modal').trigger 'reveal:close'
                        $('#edit_project_'+id).remove()
                    catch error
                        myCodeMirror.openDialog root.json_error
                        console.log error

            "click .add_project": (ev)->
                ev.preventDefault()
                $("#add_project").remove()
                root.dialog 'add_project', 'New project', '<div id="project_editor"><button class="right save_new_project" style="margin-top: 6px;">Save</button> </div>'
                root.cm_config.value = JSON.stringify(root.project_template, `undefined`, 4)
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#add_project #project_editor').prepend elt
                ,
                    root.cm_config
                )
                $(".save_new_project").click (ev)->
                    ev.preventDefault()
                    try
                        project = $.parseJSON(myCodeMirror.getValue())
                        project['owner'] = Meteor.user()._id
                        root.PROJECTS.insert project
                        $('.reveal-modal').trigger 'reveal:close'
                        $("#add_project").remove()
                    catch error
                        myCodeMirror.openDialog root.json_error
                        console.log error
)