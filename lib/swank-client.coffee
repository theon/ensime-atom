net = require('net')
{SwankParser, buildMessage} = require './swank-protocol'
{car, cdr, fromLisp} = require './lisp'
{sexpToJObject} = require './swank-extras'
{log} = require './utils'
{formatCompletionsSignature} = require './formatting'

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




# 15:48:18.030 [Thread-10] INFO  o.e.s.protocol.swank.SwankProtocol - Received msg: (:swank-rpc (swank:type-at-point "/Users/viktor/dev/projects/ensime-test-project/src/main/scala/Foo.scala" 368) 8)
# 15:48:18.037 [ENSIME-akka.actor.default-dispatcher-3] INFO  o.e.s.protocol.swank.SwankProtocol - Writing: (:return (:ok (:arrow-type t :name "[T](it: => T)(implicit computer: net.liftweb.util.CanBind[T])net.liftweb.util.CssSel" :type-id 5 :result-type (:arrow-type nil :name "CssSel" :type-id 6 :decl-as trait :full-name "net.liftweb.util.CssSel" :type-args nil :members nil :pos nil :outer-type-id nil) :param-sections ((:params (("it" (:arrow-type nil :name "<byname>" :type-id 2 :decl-as class :full-name "scala.<byname>" :type-args ((:arrow-type nil :name "T" :type-id 3 :decl-as nil :full-name "net.liftweb.util.T...
# 15:48:20.255 [Thread-10] INFO  o.e.s.protocol.swank.SwankProtocol - Received msg: (:swank-rpc (swank:inspect-type-at-point "/Users/viktor/dev/projects/ensime-test-project/src/main/scala/Foo.scala" 368) 9)
# 15:48:20.616 [ENSIME-akka.actor.default-dispatcher-3] INFO  o.e.s.protocol.swank.SwankProtocol - Writing: (:return (:ok (:type (:arrow-type t :name "[T](it: => T)(implicit computer: net.liftweb.util.CanBind[T])net.liftweb.util.CssSel" :type-id 5 :result-type (:arrow-type nil :name "CssSel" :type-id 6 :decl-as trait :full-name "net.liftweb.util.CssSel" :type-args nil :members nil :pos nil :outer-type-id nil) :param-sections ((:params (("it" (:arrow-type nil :name "<byname>" :type-id 2 :decl-as class :full-name "scala.<byname>" :type-args ((:arrow-type nil :name "T" :type-id 3 :decl-as nil :full-name "net.liftweb...

#(:return (:ok (:name "#>" :local-name "#>" :decl-pos nil :type (:arrow-type t :name "[T](it: => T)(implicit computer: net.liftweb.util.CanBind[T])net.liftweb.util.CssSel" :type-id 6 :result-type (:arrow-type nil :name "CssSel" :type-id 7 :decl-as trait :full-name "net.liftweb.util.CssSel" :type-args nil :members nil :pos nil :outer-type-id nil) :param-sections ((:params (("it" (:arrow-type nil :name "<byname>" :type-id 3 :decl-as class :full-name "scala.<byname>" :type-args ((:arrow-type nil :name "T" :type...


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
    swankMsg = "(swank:typecheck-file \"#{b.getPath()}\" #{JSON.stringify(b.getText())})"
    log("swankMsg: #{swankMsg}")
    @post(swankMsg, (result) ->)

  typecheckFile: (b) =>
    swankMsg = "(swank:typecheck-file \"#{b.getPath()}\")"
    log("swankMsg: #{swankMsg}")
    @post(swankMsg, (result) ->)
