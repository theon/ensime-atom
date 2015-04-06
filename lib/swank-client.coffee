net = require('net')
{SwankParser, buildMessage} = require './swank-protocol'
{car, cdr, fromLisp} = require './lisp'
{sexpToJObject} = require './swank-extras'



module.exports =
class SwankClient
  constructor: (port, generalMsgHandler) ->
    @ensimeMessageCounter = 1
    @callbackMap = {}

    @parser = new SwankParser( (msg) =>
      console.log("Received from Ensime server: #{msg}")
      head = car(msg)
      headStr = head.toString()

      # If :return - lookup in map, otherwise use some general function for handling general msgs
      if(headStr == ":return")
        # TODO:
        # callback from map using message counter
        returned = cdr(msg)
        answer = car(returned)
        msgCounter = parseInt(car(cdr(returned)))
        console.log("return msg for #{msgCounter}: #{answer}")

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

    @socket.on('error', ->
      console.log("Ensime server error event")
    )

    @socket.on('timeout', ->
      console.log("Ensime server timeout event")
    )

  # Public:
  sendAndThen: (msg, callback) =>
    swankMsg = buildMessage("(:swank-rpc #{msg} #{@ensimeMessageCounter})")
    @callbackMap[@ensimeMessageCounter++] = callback
    @socket.write(swankMsg)
