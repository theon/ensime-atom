net = require('net')
{SwankParser} = require './swank-protocol'

module.exports =
class SwankClient
  constructor(generalHandler):->
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
      else
        generalHandler(msg)

    )


  openSocket: (port) ->
    @socket = net.connect({port: port, allowHalfOpen: true}, ->
      console.log('client connected')
    )

    @socket.on('data', (data) =>
      handle(data)
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


  askAndThen = (msg, callback) =>
    swankMsg = swankProtocol.buildMessage("(:swank-rpc #{msg} #{@ensimeMessageCounter++})")
    callbackMap[@ensimeMessageCounter] = callback
    @socket.write(swankMsg)
