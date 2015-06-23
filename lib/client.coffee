net = require('net')
{log} = require './utils'
{formatCompletionsSignature} = require './formatting'
Swank = require './lisp/swank-protocol'
_ = require 'lodash'

module.exports =
class Client
  constructor: (port, generalMsgHandler) ->
    @ensimeMessageCounter = 1
    @callbackMap = {}



    @parser = new Swank.SwankParser( (env) =>
      console.log("Received from Ensime server: #{env}")
#      "{"msg":{"implementation":{"name":"ENSIME"},"version":"0.8.15"},"callId":1}"
      json = JSON.parse(env)
      callId = json.callId
      # If :return - lookup in map, otherwise use some general function for handling general msgs
      if(callId)
        try
          @callbackMap[callId](json.msg)
        catch error
          console.log("error in callback: #{error}")
        finally
          delete @callbackMap[callId]

      else
        generalMsgHandler(json) # We let swank leak for now because I don't really know how (:clear-scala-notes) should
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

  postString: (msg, callback) =>
    swankMsg = Swank.buildMessage """{"req": #{msg}, "callId": #{@ensimeMessageCounter}}"""
    @callbackMap[@ensimeMessageCounter++] = callback
    log("socket messages: " + swankMsg)
    @socket.write(swankMsg)

  # Public:
  post: (msg, callback) ->
    @postString(JSON.stringify(msg), callback)



  goToTypeAtPoint: (textBuffer, bufferPosition) =>
    offset = textBuffer.characterIndexForPosition(bufferPosition)
    file = textBuffer.getPath()
    @post("(swank:symbol-at-point \"#{file}\" #{offset})", (msg) ->
      # (:return (:ok (:arrow-type nil :name "Ingredient" :type-id 3 :decl-as class :full-name "se.kostbevakningen.model.record.Ingredient" :type-args nil :members nil :pos (:type offset :file "/Users/viktor/dev/projects/kostbevakningen/src/main/scala/se/kostbevakningen/model/record/Ingredient.scala" :offset 545) :outer-type-id nil)) 3)
      pos = msg[":ok"]?[":decl-pos"]
      # Sometimes no pos
      if(pos)
        targetFile = pos[":file"]
        targetOffset = pos[":offset"]
        #console.log("targetFile: #{targetFile}")
        atom.workspace.open(targetFile).then (editor) ->
          targetEditorPos = editor.getBuffer().positionForCharacterIndex(parseInt(targetOffset))
          editor.setCursorScreenPosition(targetEditorPos)
      else
        log("No :decl-pos in response from Ensime, cannot go anywhere")
    )

  ###
    (:prefix "te" :completions ((:name "test" :type-sig (((("x" "Int") ("y" "Int"))) "Int")
    :type-id 9 :is-callable t :relevance 90 :to-insert nil) (:name "text" :type-sig (nil "text$") :type-id 5 :is-callable nil
    :relevance 80 :to-insert nil)


    (:name "templates" :type-sig (nil "templates$") :type-id 3 :is-callable nil :relevance 80 :to-insert nil)
     (:name "Terminator" :type-sig (nil "Terminator$") :type-id 6 :is-callable nil :relevance 70 :to-insert nil)
      (:name "TextAreaLength" :type-sig (nil "Int") :type-id 4 :is-callable nil :relevance 70 :to-insert nil))))
  ###

  getCompletions: (textBuffer, bufferPosition, callback) =>
    file = textBuffer.getPath()
    offset = textBuffer.characterIndexForPosition(bufferPosition)
    msg = "(swank:completions (:file \"#{file}\" :contents #{JSON.stringify(textBuffer.getText())}) #{offset} 5 nil)"
    @post(msg, (result) ->
      swankCompletions = result[':ok']?[':completions']


      # TODO: This gave problem probably finalize:
# (:return (:ok (:prefix "f" :completions ((:name "foo" :type-sig (() "String") :type-id 2660) (:name "finalize" :type-sig ((()) "Unit") :type-id 12 :is-callable t)))) 91)
      if(swankCompletions) # Sometimes not, (:return (:ok (:prefix "sdf")) 5)
        translate = (c) -> # (:return (:ok (:prefix "baz" :completions ((:name "baz" :type-sig (() "Int") :type-id 1)))) 4)
          typeSig = c[':type-sig']
          formattedSignature = formatCompletionsSignature(typeSig[0])
          typeId = c[":type-id"]
          log("Formatted params: " + formattedSignature)
          {leftLabel: typeSig[1], snippet: "#{c[':name']}(#{formattedSignature})"}

        completions = (translate c for c in swankCompletions)
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


  typecheckBuffer: (b) =>
    msg = {"typehint":"TypecheckFileReq","fileInfo":{"file":"#{b.getPath()}","contents":"#{JSON.stringify(b.getText())}"}}
    @post(msg, (result) ->)

  typecheckFile: (b) =>
    msg = {"typehint":"TypecheckFileReq","fileInfo":{"file":"#{b.getPath()}"}}
    @post(msg, (result) ->)

  # TODO: make it incremental if perf. issue. Now this requests the whole thing every time
  # Probably need to branch out code-links and make something more custom with control over life cycle.
  # then we can ask for symbol-designations while typing incrementally
  # TODO: Move out to symbol-designations module
  getSymbolDesignations: (editor) ->
    b = editor.getBuffer()
    range = b.getRange()
    startO = b.characterIndexForPosition(range.start)
    endO = b.characterIndexForPosition(range.end)

    # TODO: contents:
    msg = {
      "typehint":"SymbolDesignationsReq"
      "requestedTypes": symbolTypehints
      "file": b.getPath()
      "start": startO
      "end": endO
    }

    @post(msg, (result) ->
      syms = result.syms

      decorate = (sym) ->
        startPos = b.positionForCharacterIndex(parseInt(sym[1]))
        endPos = b.positionForCharacterIndex(parseInt(sym[2]))
        marker = editor.markBufferRange([startPos, endPos],
                invalidate: 'inside',
                class: "scala #{sym[0]}"
                )
        decoration = editor.decorateMarker(marker,
          type: 'highlight',
          class: sym[0]
        )
        marker

      decorations = decorate sym for sym in syms

    )
    []

    #(:return (:ok (:file "/Users/viktor/dev/projects/ensime-test-project/src/main/scala/Foo.scala" :syms ((param 305 306) (param 309 310) (valField 319 331)))) 3)


symbols = ["ObjectSymbol"
,"ClassSymbol"
,"TraitSymbol"
,"PackageSymbol"
,"ConstructorSymbol"
,"ImportedNameSymbol"
,"TypeParamSymbol"
,"ParamSymbol"
,"VarFieldSymbol"
,"ValFieldSymbol"
,"OperatorFieldSymbol"
,"VarSymbol"
,"ValSymbol"
,"FunctionCallSymbol"]

symbolTypehints = _.map(symbols, (symbol) -> {"typehint": "#{symbol}"})
