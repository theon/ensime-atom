
module.exports =
class Processor

  constructor: (@clientProxy) ->
    console.log("provide-links-processor instantiated")

  #atom.workspace.getActiveTextEditor().getRootScopeDescriptor()
  scopes: ['source.scala']

  process: (editor) ->
    console.log("provide-links-processor processing #{editor}")
    client = @clientProxy.getClient()
    if(client)
      client.getSymbolDesignations(editor)
    else
      []

  followLink: (srcFilename, info) ->
    ""
