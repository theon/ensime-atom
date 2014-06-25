EnsimeView = require './ensime-view'
net = require('net')
exec = require('child_process').exec
fs = require 'fs'
swankProtocol = require './swank-protocol'


ensimeMessageCounter = 1

swankRpc = (msg) ->
  swankProtocol.buildMessage("(:swank-rpc #{msg} #{ensimeMessageCounter++})")

readDotEnsime = -> # TODO: error handling
  fs.readFileSync(atom.project.getPath() + '/.ensime')

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
  client = net.connect({port: port}, ->
    console.log('client connected')
    sendFunction(client)
  )
  client

module.exports =
  ensimeView: null

  activate: (state) ->
    atom.packages.once 'activated', ->
      atom.workspaceView.statusBar?.appendLeft('<span>Starting Ensime server?</span>')

    atom.workspaceView.command "ensime:init", => @initEnsime()
    @ensimeView = new EnsimeView(state.ensimeViewState)

  deactivate: ->
    @ensimeView.destroy()

  serialize: ->
    ensimeViewState: @ensimeView.serialize()

  initEnsime: ->
    loadSettings = atom.getLoadSettings()
    console.log('loadSettings: ' + loadSettings)
    projectPath = atom.project.getPath()
    console.log('project path: ' + projectPath)
    portFile = projectPath + '/ensime_port'

    # Start the ensime server
    startEnsime(portFile)

    setTimeout(->
      # Open up socket to the server
      client = openSocketAndSend(portFile, (c) ->
        connectionMsg = swankRpc('(swank:connection-info)')
        console.log("Connection msg: #{connectionMsg}")
        c.write(swankRpc('(swank:connection-info)'))

        dotEnsime = readDotEnsime()
        console.log(".ensime content: #{dotEnsime}")

        c.write(swankRpc("(swank:init-project #{dotEnsime})"))
      )

      client.on('data', (data) ->
        console.log('received data from Ensime server: ' + data.toString())
      )

      client.on('end', ->
        console.log("Ensime server disconnected")
      )
    , 1000)

    editor = atom.workspace.activePaneItem
    #editor.insertText('Starting Ensime server...')

    atom.workspaceView.statusBar.appendLeft('Starting Ensime server…')

#  typecheckAll: ->
