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

    #TODO: Can I add a lostFocus-handler to mitigate: https://github.com/ensime/ensime-atom/issues/1

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

    req =
      typehint: "SymbolAtPointReq"
      #typehint: "TypeAtPointReq"
      file: @editor.getPath()
      point: offset

    @client.post(req, (msg) =>
      if msg.typehint == 'SymbolInfo'
        @exprTypeTooltip?.updateText(formatType(msg.type))
      else
        # if msg.typehint == 'FalseResponse'
        # do nothing
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
