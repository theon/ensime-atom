{SwankParser} = require './swank-protocol'


module.exports =
  EnsimeReceiver: new SwankParser( (msg) ->
    console.log("received msg: #{msg}")
    )
