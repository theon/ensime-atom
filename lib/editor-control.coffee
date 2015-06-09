{Subscriber} = require 'emissary'
{TooltipView} = require './tooltip-view'
{CompositeDisposable} = require 'atom'
$ = require 'jquery'
{pixelPositionFromMouseEvent, screenPositionFromMouseEvent, getElementsByClass} = require './utils'


class EditorControl
  constructor: (@editor, @client) ->
    @disposables = new CompositeDisposable

    @editorView = atom.views.getView(@editor);

    @scroll = $(getElementsByClass(@editorView, '.scroll-view'))

    @subscriber = new Subscriber()

    @typecheckWhileTypingSubscriber = new Subscriber()

    @editor.onDidDestroy =>
      @deactivate()


    # buffer events for automatic check
    buffer = @editor.getBuffer()
    @disposables.add buffer.onDidSave () =>

      # TODO if uri was changed, then we have to remove all current markers
      workspaceElement = atom.views.getView(atom.workspace)

      # typecheck file on save
      if atom.config.get('Ensime.typecheckWhen') in ['save', 'typing']
        atom.commands.dispatch workspaceElement, 'ensime:typecheck-file'

    @subscriber.subscribe @scroll, 'mousemove', (e) =>
      @clearExprTypeTimeout()
      @exprTypeTimeout = setTimeout (=>
        @showExpressionType e
      ), 100


    @subscriber.subscribe @scroll, 'mouseout', (e) =>
      @clearExprTypeTimeout()

    # Typecheck buffer while typing
    atom.config.observe 'Ensime.typecheckWhen', (value) =>
      if(value == 'typing')
        @typecheckWhileTypingSubscriber.subscribe @scroll, 'keydown', (e) =>
          @clearTypecheckTimeout()
          workspaceElement = atom.views.getView(atom.workspace) # TODO: what is this really?
          @typecheckTimeout = setTimeout (=>
            @client.typecheckBuffer(@editor.getBuffer())
          ), atom.config.get('Ensime.typecheckTypingDelay')
      else
        @typecheckWhileTypingSubscriber.unsubscribe()


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
    @clearExprTypeTimeout()
    @subscriber.unsubscribe()
    @typecheckWhileTypingSubscriber.unsubscribe()
    @disposables.dispose()
    @editorView.control = undefined


  # helper function to hide tooltip and stop timeout
  clearExprTypeTimeout: ->
    if @exprTypeTimeout?
      clearTimeout @exprTypeTimeout
      @exprTypeTimeout = null
    @hideExpressionType()


  clearTypecheckTimeout: ->
    if @typecheckTimeout?
      clearTimeout @typecheckTimeout
      @typecheckTimeout = null

  # get expression type under mouse cursor and show it
  showExpressionType: (e) ->
    return if @exprTypeTooltip?

    pixelPt = pixelPositionFromMouseEvent(@editor, e)
    screenPt = @editor.screenPositionForPixelPosition(pixelPt)
    bufferPt = @editor.bufferPositionForScreenPosition(screenPt)
    nextCharPixelPt = @editorView.pixelPositionForBufferPosition([bufferPt.row, bufferPt.column + 1])

    return if pixelPt.left >= nextCharPixelPt.left

    # find out show position
    offset = @editor.getLineHeightInPixels() * 0.7
    tooltipRect =
      left: e.clientX
      right: e.clientX
      top: e.clientY - offset
      bottom: e.clientY + offset

    # create tooltip with pending
    @exprTypeTooltip = new TooltipView(tooltipRect)


    textBuffer = @editor.getBuffer()
    offset = textBuffer.characterIndexForPosition(bufferPt)

    @client.post("(swank:type-at-point \"#{@editor.getPath()}\" #{offset})", (msg) =>
      # (:return (:ok (:arrow-type nil :name "Ingredient" :type-id 3 :decl-as class :full-name "se.kostbevakningen.model.record.Ingredient" :type-args nil :members nil :pos (:type offset :file "/Users/viktor/dev/projects/kostbevakningen/src/main/scala/se/kostbevakningen/model/record/Ingredient.scala" :offset 545) :outer-type-id nil)) 3)
      fullName = msg[":ok"]?[":full-name"]
      #console.log("EditorControl recieved msg from ensime: #{msg}. @exprTypeTooltip = #{@exprTypeTooltip}")
      @exprTypeTooltip?.updateText(fullName)
    )


  hideExpressionType: ->
    if @exprTypeTooltip?
      @exprTypeTooltip.remove()
      @exprTypeTooltip = null


module.exports = EditorControl
