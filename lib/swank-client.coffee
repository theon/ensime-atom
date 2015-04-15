net = require('net')
{SwankParser, buildMessage} = require './swank-protocol'
{car, cdr, fromLisp} = require './lisp'
{sexpToJObject} = require './swank-extras'
{log} = require './utils'


module.exports =
class SwankClient
  constructor: (port, generalMsgHandler) ->
    @ensimeMessageCounter = 1
    @callbackMap = {}

    @parser = new SwankParser( (msg) =>
      #console.log("Received from Ensime server: #{msg}")
      head = car(msg)
      headStr = head.toString()

      # If :return - lookup in map, otherwise use some general function for handling general msgs
      if(headStr == ":return")
        # TODO:
        # callback from map using message counter
        returned = cdr(msg)
        answer = car(returned)
        msgCounter = parseInt(car(cdr(returned)))
        #console.log("return msg for #{msgCounter}: #{answer}")

        try
          @callbackMap[msgCounter](sexpToJObject(answer))
        catch error
          console.log("error in callback: #{error}")
        finally
          delete @callbackMap[msgCounter]

      else
        generalMsgHandler(msg) # We let swank leak for now because I don't really know how (:clear-scala-notes) should
        # be translated into json. So unfortunately direct deps from main to car/cdr and such.

    )
    @openSocket(port)

  destroy: ->
    @socket.destroy()

  openSocket: (port) ->
    @socket = net.connect({port: port, allowHalfOpen: true} , ->
      console.log('client connected')
    )

    @socket.on('data', (data) =>
      @parser.execute(data)
    )

    @socket.on('end', ->
      console.log("Ensime server disconnected")
    )

    @socket.on('close', ->
      console.log("Ensime server close event")
    )

    @socket.on('error', (data) ->
      console.log("Ensime server error event: " + data)
    )

    @socket.on('timeout', ->
      console.log("Ensime server timeout event")
    )

  # Public:
  post: (msg, callback) =>
    swankMsg = buildMessage("(:swank-rpc #{msg} #{@ensimeMessageCounter})")
    @callbackMap[@ensimeMessageCounter++] = callback
    @socket.write(swankMsg)


  goToTypeAtPoint: (textBuffer, bufferPosition) =>
    offset = textBuffer.characterIndexForPosition(bufferPosition)
    file = textBuffer.getPath()
    @post("(swank:type-at-point \"#{file}\" #{offset})", (msg) ->
      # (:return (:ok (:arrow-type nil :name "Ingredient" :type-id 3 :decl-as class :full-name "se.kostbevakningen.model.record.Ingredient" :type-args nil :members nil :pos (:type offset :file "/Users/viktor/dev/projects/kostbevakningen/src/main/scala/se/kostbevakningen/model/record/Ingredient.scala" :offset 545) :outer-type-id nil)) 3)
      pos = msg[":ok"]?[":pos"]
      targetFile = pos[":file"]
      targetOffset = pos[":offset"]
      #console.log("targetFile: #{targetFile}")
      atom.workspace.open(targetFile).then (editor) ->
        targetEditorPos = editor.getBuffer().positionForCharacterIndex(parseInt(targetOffset))
        editor.setCursorScreenPosition(targetEditorPos)

      )

  getCompletions: (textBuffer, bufferPosition, callback) =>
    file = textBuffer.getPath()
    offset = textBuffer.characterIndexForPosition(bufferPosition)
    msg = "(swank:completions (:file \"#{file}\" :contents #{JSON.stringify(textBuffer.getText())}) #{offset} 5 nil)"
    @post(msg, (result) ->
      swankCompletions = result[':ok']?[':completions']
      completions = ({text: c[':name'], type: JSON.stringify(c[':type-sig'])} for c in swankCompletions)
      ### Autocomplete + :
      suggestion =
        text: 'someText' # OR
        snippet: 'someText(${1:myArg})'
        replacementPrefix: 'so' # (optional)
        type: 'function' # (optional)
        leftLabel: '' # (optional)
        leftLabelHTML: '' # (optional)
        rightLabel: '' # (optional)
        rightLabelHTML: '' # (optional)
        iconHTML: '' # (optional)
      ###
      callback(completions)
    )
