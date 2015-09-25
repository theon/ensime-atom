{bufferPositionFromMouseEvent} = require '../utils'
{formatType} = require '../formatting'
SubAtom = require 'sub-atom'

class GoToType
  constructor: (@editor, @client) ->
    @disposables = new SubAtom
    @editorElement = atom.views.getView(@editor).rootElement


    @disposables.add atom.config.observe 'Ensime.modifierKeyForJumpToDefinition', (value) =>
      @modifierSetting = value

    @disposables.add @editorElement, 'mousedown', '.scroll-view', (e) =>
      {detail, shiftKey, metaKey, ctrlKey, altKey} = e

      if (@modifierSetting == 'alt' and altKey) or (@modifierSetting == 'ctrl' and ctrlKey) or (@modifierSetting == 'cmd' and metaKey)
        e.preventDefault()
        e.stopImmediatePropagation()
        @jump(e)
      else


  jump: (e) ->
    bufferPt = bufferPositionFromMouseEvent(@editor, e)
    @client.goToTypeAtPoint(@editor.getBuffer(), bufferPt)


  deactivate: ->
    @disposables.dispose()


module.exports = GoToType
