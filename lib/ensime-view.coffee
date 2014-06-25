{View} = require 'atom'

module.exports =
class EnsimeView extends View
  @content: ->
    @div class: 'ensime overlay from-top', =>
      @div "The Ensime package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "ensime:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "EnsimeView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
