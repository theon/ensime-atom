{Subscriber} = require 'emissary'
{TooltipView} = require '../views/tooltip-view'
$ = require 'jquery'
{pixelPositionFromMouseEvent, getElementsByClass} = require '../utils'
{formatType} = require '../formatting'

class ShowTypes
  constructor: (@editor, @client) ->
    @subscriber = new Subscriber()

    @editorView = atom.views.getView(@editor);

    @scroll = $(getElementsByClass(@editorView, '.scroll-view'))

    @subscriber.subscribe @scroll, 'mousemove', (e) =>
      @clearExprTypeTimeout()
      @exprTypeTimeout = setTimeout (=>
        @showExpressionType e
      ), 100


    @subscriber.subscribe @scroll, 'mouseout', (e) =>
      @clearExprTypeTimeout()

    @editor.onDidDestroy =>
      @deactivate()

  # get expression type under mouse cursor and show it
  showExpressionType: (e) ->
    return if @exprTypeTooltip?

    pixelPt = pixelPositionFromMouseEvent(@editor, e)
    screenPt = @editor.screenPositionForPixelPosition(pixelPt)
    bufferPt = @editor.bufferPositionForScreenPosition(screenPt)
    nextCharPixelPt = @editorView.pixelPositionForBufferPosition([bufferPt.row, bufferPt.column + 1])

    return if pixelPt.left >= nextCharPixelPt.left

    # find out show position
    rectOffset = @editor.getLineHeightInPixels() * 0.7
    tooltipRect =
      left: e.clientX
      right: e.clientX
      top: e.clientY - rectOffset
      bottom: e.clientY + rectOffset

    # create tooltip with pending
    @exprTypeTooltip = new TooltipView(tooltipRect)


    textBuffer = @editor.getBuffer()
    offset = textBuffer.characterIndexForPosition(bufferPt)


    req = """{"typehint":"TypeAtPointReq","file":"#{@editor.getPath()}","range":{"from":#{offset},"to":#{offset}}}"""

    @client.postString(req, (msg) =>
      # (:return (:ok (:arrow-type nil :name "Ingredient" :type-id 3 :decl-as class :full-name "se.kostbevakningen.model.record.Ingredient" :type-args nil :members nil :pos (:type offset :file "/Users/viktor/dev/projects/kostbevakningen/src/main/scala/se/kostbevakningen/model/record/Ingredient.scala" :offset 545) :outer-type-id nil)) 3)


      @exprTypeTooltip?.updateText(formatType(okMsg))

    )

  deactivate: ->
    @clearExprTypeTimeout()
    @subscriber.unsubscribe()

  # helper function to hide tooltip and stop timeout
  clearExprTypeTimeout: ->
    if @exprTypeTimeout?
      clearTimeout @exprTypeTimeout
      @exprTypeTimeout = null
    @hideExpressionType()

  hideExpressionType: ->
    if @exprTypeTooltip?
      @exprTypeTooltip.remove()
      @exprTypeTooltip = null

module.exports = ShowTypes
