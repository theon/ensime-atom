net = require('net')
exec = require('child_process').exec
fs = require 'fs'
swankProtocol = require './swank-protocol'
{Subscriber} = require 'emissary'
EnsimeReceiver = require './ensime-receiver'


ensimeMessageCounter = 1
client = null


_portFile = null
portFile = ->
  if(_portFile) then _portFile else
    loadSettings = atom.getLoadSettings()
    console.log('loadSettings: ' + loadSettings)
    projectPath = atom.project.getPath()
    console.log('project path: ' + projectPath)
    _portFile = projectPath + '/.ensime_cache/port'
    _portFile

swankRpc = (msg) ->
  msg = swankProtocol.buildMessage("(:swank-rpc #{msg} #{ensimeMessageCounter++})")
  console.log("msg to ensime server: #{msg}")
  msg

readDotEnsime = -> # TODO: error handling
  raw = fs.readFileSync(atom.project.getPath() + '/.ensime')
  rows = raw.toString().split(/\r?\n/);
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')

startEnsime = (portFile) ->
  ensimeLocation = '~/dev/projects/ensime-src/dist'
  #ensimeServerBin = ensimeLocation + '/2.10/bin/server'
  ensimeServerBin = ensimeLocation + '/2.11/bin/server'
  command = 'cd ' + ensimeLocation + '\n' + ensimeServerBin + ' ' + portFile
  console.log("Running command: " + command)
  child = exec(command, (error, stdout, stderr) ->
    console.log('stdout: ' + stdout);
    console.log('stderr: ' + stderr);
    if(error != null)
      console.log('exec error: ' + error);
  )

openSocketAndSend = (portFileLoc, sendFunction) ->
  console.log("portFileLoc: " + portFileLoc)
  port = fs.readFileSync(portFileLoc)
  console.log("portFile contents: " + port)
  client = net.connect({port: port, allowHalfOpen: true}, ->
    console.log('client connected')
    sendFunction(client)
  )
  client

getServerInfo = (c) ->
  connectionMsg = swankRpc('(swank:connection-info)')
  console.log("Connection msg: #{connectionMsg}")
  c.write(connectionMsg)

initWithDotEnsime = (c) ->
  initMsg = swankRpc("(swank:init-project)")
  console.log("Init Msg: #{initMsg}")
  c.write(initMsg)


module.exports = Ensime =
  activate: (state) ->
    atom.workspaceView.command "ensime:init", => @initEnsime()
    atom.workspaceView.command "ensime:start-server", => @startEnsime()
    atom.workspaceView.command "ensime:typecheck-all", => @typecheckAll()
    atom.workspaceView.command "ensime:init-builder", => @initBuilder()
    atom.workspaceView.command "ensime:go-to-definition", => @goToDefinition()


  deactivate: ->

  serialize: ->

  startEnsime: ->
    startEnsime(portFile())

  initEnsime: ->
    @receiver = new EnsimeReceiver

    # Open up socket to the server
    client = openSocketAndSend(portFile(), (c) ->
      #getServerInfo(c)
      initWithDotEnsime(c)
    )

    client.on('data', (data) =>
      @receiver.handle(data)
    )

    client.on('end', ->
      console.log("Ensime server disconnected")
    )

    client.on('close', ->
      console.log("Ensime server close event")
    )

    client.on('error', ->
      console.log("Ensime server error event")
    )

    client.on('timeout', ->
      console.log("Ensime server timeout event")
    )

  typecheckAll: ->
    client.write(swankRpc("(swank:typecheck-all)"))

  initBuilder: ->
    client.write(swankRpc("(swank:builder-init)"))

  goToDefinition: ->
    editor = atom.workspace.getActiveTextEditor()
    textBuffer = editor.getBuffer()
    pos = editor.getCursorBufferPosition()
    offset = textBuffer.characterIndexForPosition(pos)
    file = textBuffer.getPath()
    client.write(swankRpc("(swank:type-at-point \"#{file}\" #{offset})"))

    # TODO: skapa en aux-funktion som tar ett meddelande och en function för att hantera svaret och som sparar ned
    # numret mot funktionen och ropar på den när svaret kommer

    ###
Received from Ensime server: (:return (:ok (:arrow-type nil :name "RequestVar" :type-id 1 :decl-as class :full-name "net.liftweb.http.RequestVar" :type-args ((:arrow-type nil :name "String" :type-id 2 :decl-as class :full-name "java.lang.String" :type-args nil :members nil :pos nil :outer-type-id nil)) :members nil :pos (:type offset :file "/Users/viktor/dev/projects/kostbevakningen/.ensime_cache/dep-src/source-jars/net/liftweb/http/Vars.scala" :offset 14259) :outer-type-id nil)) 2)
ensime-receiver.coffee:21 Head: :return
ensime-receiver.coffee:22 Tail: ((:ok (:arrow-type nil :name "RequestVar" :type-id 1 :decl-as class :full-name "net.liftweb.http.RequestVar" :type-args ((:arrow-type nil :name "String" :type-id 2 :decl-as class :full-name "java.lang.String" :type-args nil :members nil :pos nil :outer-type-id nil)) :members nil :pos (:type offset :file "/Users/viktor/dev/projects/kostbevakningen/.ensime_cache/dep-src/source-jars/net/liftweb/http/Vars.scala" :offset 14259) :outer-type-id nil)) 2)



       * Doc RPC:
       *   swank:type-at-point
       * Summary:
       *   Lookup type of thing at given position.
       * Arguments:
       *   String:A source filename.
       *   Int or (Int, Int):A character offset (or range) in the file.
       * Return:
       *   A TypeInfo
       * Example call:
       *   (:swank-rpc (swank:type-at-point "SwankProtocol.scala" 32736) 42)
       * Example return:
       *   (:return (:ok (:name "String" :type-id 1188 :full-name
       *   "java.lang.String" :decl-as class)) 42)

    ###
