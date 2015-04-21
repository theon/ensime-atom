path = require 'path'

isScalaSource = (editor) ->
  buffer = editor.getBuffer()
  fname = buffer.getUri()
  return path.extname(fname) in ['.scala']

# pixel position from mouse event
pixelPositionFromMouseEvent = (editor, event) ->
  {clientX, clientY} = event
  elem = atom.views.getView(editor)
  linesClientRect = getElementsByClass(elem, ".lines")[0].getBoundingClientRect()
  top = clientY - linesClientRect.top
  left = clientX - linesClientRect.left
  {top, left}

# screen position from mouse event
screenPositionFromMouseEvent = (editor, event) ->
  editor.screenPositionForPixelPosition(pixelPositionFromMouseEvent(editor, event))

getElementsByClass = (elem,klass) ->
  elem.rootElement.querySelectorAll(klass)

devMode = atom.config.get('Ensime.devMode')

log = (toLog) ->
  if devMode
    console.log(toLog.toString())

modalMsg = (title, msg) ->
  atom.confirm
    message: title
    detailedMessage: msg
    buttons:
      Ok: ->


formatSignature = (paramLists, returnType) ->
  formatParamLists = (paramLists) ->
    formatParamList = (paramList) ->
      formatParam = (param, i) ->
        "${#{i}:#{param[0]}: #{param[1]}}"
      p = (formatParam(param, i+1) for param, i in paramList)
      p.join(", ")

    formattedParamLists = (formatParamList paramList for paramList in paramLists)
    formattedParamLists.join("|")

  formatParamLists(paramLists)


module.exports = {
  isScalaSource,
  pixelPositionFromMouseEvent,
  screenPositionFromMouseEvent,
  getElementsByClass,
  log,
  modalMsg,
  formatSignature
}
