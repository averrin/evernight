root = global ? window


Meteor.startup(->
    if root.Meteor.is_client
        root.Template.options.tabs = ->
            root.TABS.find().fetch()

        root.Template.options.events =
            "click .del_tab": (ev)->
                ev.preventDefault()
                console.log 'del tab'
                root.TABS.remove this._id

            "click .edit_tab": (ev)->
                ev.preventDefault()
                id = this._id
                $('#edit_tab_'+id).remove()
                root.dialog 'edit_tab_'+id, this.title,
                    '<div id="tab_editor">
                        <button class="right save_tab" style="margin-top: 6px;" data-uuid="'+id+'">Save</button>
                    </div>'
                cc = {}
                cc = $.extend cc, root.cm_config
                cc.value = this.content
                cc.mode = 'htmlmixed'
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#edit_tab_'+id+' #tab_editor').prepend elt
                ,
                    cc
                )
                $(".save_tab").click (ev)->
                    ev.preventDefault()
                    tab =
                        content: myCodeMirror.getValue()
                    root.TABS.update {_id: $(ev.target).attr('data-uuid')}, {$set: tab}
                    $('.reveal-modal').trigger 'reveal:close'
                    $('#edit_tab_'+id).remove()

            "click .add_tab": (ev)->
                ev.preventDefault()
                $("#add_tab").remove()
                root.dialog 'add_tab', 'New tab',
                    '<input type="text" id="tab_title" placeholder=":title"/>
                    <input type="text" id="tab_hash" placeholder="#!/hash"/> <br />
                    <input type="text" id="tab_color" placeholder="#color"/>
                    <div id="tab_editor">
                        <button class="right save_new_tab" style="margin-top: 6px;">Save</button>
                    </div>'
                cc = {}
                cc = $.extend cc, root.cm_config
                cc.value = ''
                cc.mode = 'htmlmixed'
                root.myCodeMirror = root.CodeMirror((elt) ->
                    $('#add_tab #tab_editor').prepend elt
                ,
                    cc
                )
                $(".save_new_tab").click (ev)->
                    ev.preventDefault()
                    tab =
                        title: $('#tab_title').val()
                        hash: $("#tab_hash").val()
                        content: myCodeMirror.getValue()
                        color: $("#tab_color").val()
                        owner: Meteor.user()._id
                    root.TABS.insert tab
                    $('.reveal-modal').trigger 'reveal:close'
                    $("#add_tab").remove()
)