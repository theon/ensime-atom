{View} = require 'atom'

module.exports =
  class StatusbarView extends View
    @content: ->
      @div class: 'ensime-status inline-block'

    initialize: ->

    serialize: ->

    init: ->
      console.log("StatusbarView#init called")
      #atom.packages.once('activated', @attach)
      @attach()

    attach: =>
      console.log("attach in statusbar view")
      statusbar = atom.workspaceView.statusBar
      statusbar.appendLeft this

    setText: (text) =>
      @text("Ensime: #{text}").show()

    destroy: ->
      @detach()
