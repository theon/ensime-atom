{Subscriber} = require 'emissary'
{CompositeDisposable} = require 'atom'
$ = require 'jquery'
{pixelPositionFromMouseEvent, screenPositionFromMouseEvent, getElementsByClass} = require './utils'
{formatType} = require './formatting'

class EditorControl
  constructor: (@editor, @client) ->
    @disposables = new CompositeDisposable

    @editorView = atom.views.getView(@editor);

    @scroll = $(getElementsByClass(@editorView, '.scroll-view'))

    @subscriber = new Subscriber()

    @editor.onDidDestroy =>
      @deactivate()


    # buffer events for automatic check
    buffer = @editor.getBuffer()
    @disposables.add buffer.onDidSave () =>

      # TODO if uri was changed, then we have to remove all current markers
      workspaceElement = atom.views.getView(atom.workspace)

      # typecheck file on save
      if atom.config.get('Ensime.typecheckWhen') in ['save', 'typing']
        @client.typecheckBuffer(@editor.getBuffer())



    # Typecheck buffer while typing
    atom.config.observe 'Ensime.typecheckWhen', (value) =>
      if(value == 'typing')
        @typecheckWhileTypingDisposable = @editor.onDidStopChanging () =>
          @client.typecheckBuffer(@editor.getBuffer())


        @disposables.add @typecheckWhileTypingDisposable


      else
        @disposables.remove @typecheckWhileTypingDisposable
        @typecheckWhileTypingDisposable?.dispose()


    # Try something like https://github.com/atom/atom/blob/master/src/text-editor-component.coffee#L365
    # Maybe first mark with underline and change pointer on hover and when clicking, do the jump
    @subscriber.subscribe @scroll, 'mousedown', (e) =>
      {detail, shiftKey, metaKey, ctrlKey, altKey} = e
      pixelPt = pixelPositionFromMouseEvent(@editor, e)
      screenPt = @editor.screenPositionForPixelPosition(pixelPt)
      bufferPt = @editor.bufferPositionForScreenPosition(screenPt)
      buffer = @editor.getBuffer()
      if(altKey) then @client.goToTypeAtPoint(buffer, bufferPt)


  deactivate: ->
    @subscriber.unsubscribe()
    @disposables.dispose()




  clearTypecheckTimeout: ->
    if @typecheckTimeout?
      clearTimeout @typecheckTimeout
      @typecheckTimeout = null







module.exports = EditorControl
