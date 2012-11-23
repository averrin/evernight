root = global ? window

Meteor.startup(->
    if root.Meteor.is_client       
        
        root.Template.configs.configs = ->
            root.CONFIGS.find().fetch()
            
            
        root.Template.configs.events = 
            "click .add_config": (ev)->
                ev.preventDefault()
                $("#add_config").remove()
                root.dialog 'add_config', 'New server',
                    '<input placeholder=":title" id="config_title"> <br>
                    <input placeholder=":comment" id="config_comment">
                    <div id="config_editor">
                        <button class="right save_new_config" style="margin-top: 6px;">Save</button>
                    </div>'
                root.cm_config.value = ''
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#add_config #config_editor').prepend elt
                ,
                    root.cm_config
                )
                $(".save_new_config").click (ev)->
                    ev.preventDefault()
                    $('.reveal-modal').trigger 'reveal:close'
                    config =
                        title: $('#config_title').val()
                        comment: $('#config_comment').val()
                        content: myCodeMirror.getValue()
                        owner: Meteor.user()._id
                    root.CONFIGS.insert config
                    
            "click .edit_config": (ev)->
                ev.preventDefault()
                id = this._id
                $('#edit_config_'+id).remove()
                root.dialog 'edit_config_'+id, this.title,
                    '<div id="config_editor">
                        <button class="right save_config" style="margin-top: 6px;" data-uuid="'+id+'">Save</button>
                    </div>'
                root.cm_config.value = this.content
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#edit_config_'+id+' #config_editor').prepend elt
                ,
                    root.cm_config
                )
                $(".save_config").click (ev)->
                    ev.preventDefault()
                    root.CONFIGS.update {_id: $(ev.target).attr('data-uuid')}, {$set: {content: myCodeMirror.getValue()}}
                    $('.reveal-modal').trigger 'reveal:close'
                
            "click .del_config": (ev)->
                ev.preventDefault()
                console.log 'del config'
                root.CONFIGS.remove this._id
                
            "mouseenter .side>.inverted": (ev)->
                console.log ev.target
                $(ev.target).toggleClass 'hovered'
                
)