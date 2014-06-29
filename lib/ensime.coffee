EnsimeView = require './ensime-view'
net = require('net')
exec = require('child_process').exec
fs = require 'fs'
swankProtocol = require './swank-protocol'
{Subscriber} = require 'emissary'
{EnsimeReceiver} = require './ensime-receiver'

ensimeMessageCounter = 1
client = null


_portFile = null
portFile = ->
  if(_portFile) then _portFile else
    loadSettings = atom.getLoadSettings()
    console.log('loadSettings: ' + loadSettings)
    projectPath = atom.project.getPath()
    console.log('project path: ' + projectPath)
    _portFile = projectPath + '/ensime_port'
    _portFile

swankRpc = (msg) ->
  swankProtocol.buildMessage("(:swank-rpc #{msg} #{ensimeMessageCounter++})")

readDotEnsime = -> # TODO: error handling
  raw = fs.readFileSync(atom.project.getPath() + '/.ensime')
  rows = raw.toString().split(/\r?\n/);
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')

startEnsime = (portFile) ->
  ensimeLocation = '~/dev/projects/ensime-src/dist'
  ensimeServerBin = ensimeLocation + '/2.10/bin/server'
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
  dotEnsime = readDotEnsime()

  initMsg = swankRpc("(swank:init-project #{dotEnsime})")
  console.log("Init Msg: #{initMsg}")
  c.write(initMsg)


module.exports =
  ensimeView: null

  activate: (state) ->
    atom.packages.once 'activated', ->
      atom.workspaceView.statusBar?.appendLeft('<span>Starting Ensime server?</span>')

    atom.workspaceView.command "ensime:init", => @initEnsime()
    atom.workspaceView.command "ensime:start-server", => @startEnsime()
    atom.workspaceView.command "ensime:typecheck-all", => @typecheckAll()
    atom.workspaceView.command "ensime:init-builder", => @initBuilder()
    @ensimeView = new EnsimeView(state.ensimeViewState)

  deactivate: ->
    @ensimeView.destroy()

  serialize: ->
    ensimeViewState: @ensimeView.serialize()

  startEnsime: ->
    startEnsime(portFile())

  initEnsime: ->
    # Start the ensime server
    #startEnsime(portFile)

    messageHandler = EnsimeReceiver

    # Open up socket to the server
    client = openSocketAndSend(portFile(), (c) ->
      #getServerInfo(c)
      initWithDotEnsime(c)
    )

    client.on('data', (data) ->
      console.log('received data from Ensime server: ' + data.toString())
      messageHandler.execute(data)
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


    editor = atom.workspace.activePaneItem
    #editor.insertText('Starting Ensime server...')

    atom.workspaceView.statusBar.appendLeft('Starting Ensime server…')

  typecheckAll: ->
    client.write(swankRpc("(swank:typecheck-all)"))

  initBuilder: ->
    client.write(swankRpc("(swank:builder-init)"))
