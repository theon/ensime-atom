# Download and startup of ensime server
fs = require('fs')
path = require('path')
{sexpToJObject} = require('./swank-extras')
{exec, spawn} = require('child_process')
lisp = require('./lisp')
{log, modalMsg, projectPath} = require('./utils')
EnsimeServerUpdateLogView = require('./views/ensime-server-update-log-view')
createSbtStartScript = (scalaVersion, ensimeServerVersion, classpathFile) ->
  """
  import sbt._

  import IO._

  import java.io._

  scalaVersion := \"#{scalaVersion}\"

  ivyScala := ivyScala.value map { _.copy(overrideScalaVersion = true) }

  resolvers += Resolver.sonatypeRepo(\"snapshots\")

  resolvers += \"Typesafe repository\" at \"http://repo.typesafe.com/typesafe/releases/\"

  resolvers += \"Akka Repo\" at \"http://repo.akka.io/repository\"

  libraryDependencies += \"org.ensime\" %% \"ensime\" % \"#{ensimeServerVersion}\"

  val saveClasspathTask = TaskKey[Unit](\"saveClasspath\", \"Save the classpath to a file\")

  saveClasspathTask := {
    val managed = (managedClasspath in Runtime).value.map(_.data.getAbsolutePath)
    val unmanaged = (unmanagedClasspath in Runtime).value.map(_.data.getAbsolutePath)
    val out = file(\"#{classpathFile}\")
    write(out, (unmanaged ++ managed).mkString(File.pathSeparator))
  }
  """

packageDir = atom.packages.resolvePackagePath('Ensime')
tempdir =  packageDir + "/ensime_update_"


classpathFile = (scalaVersion, ensimeServerVersion) ->
  atom.packages.resolvePackagePath('Ensime') + path.sep + "classpath_#{scalaVersion}_#{ensimeServerVersion}"


ensimeCache = -> projectPath() + '/.ensime_cache'
ensimeServerLogFile = -> ensimeCache() + '/server.log'

readDotEnsime = (path)-> # TODO: error handling
  raw = fs.readFileSync(path) # TODO: ask as Emacs?
  rows = raw.toString().split(/\r?\n/);
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')

scalaVersionOfProjectDotEnsime = (path) ->
  # scala version from .ensime config file of project
  dotEnsime = readDotEnsime(path)
  dotEnsimeLisp = lisp.readFromString(dotEnsime)
  dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
  dotEnsimeJs[':scala-version']






updateEnsimeServerManually = ->
  ensimeConfigFile = projectPath() + '/.ensime'
  scalaVersion = scalaVersionOfProjectDotEnsime(ensimeConfigFile)
  ensimeServerVersion = atom.config.get('Ensime.ensimeServerVersion')
  if not (projectPath() and fs.existsSync(ensimeConfigFile))
    modalMsg('No .ensime found', "You need to have a project open with a .ensime in root.")
  else
    updateEnsimeServer(scalaVersion, ensimeServerVersion)


updateEnsimeServer = (scalaVersion, ensimeServerVersion) ->

  #TODO: cleanup!
  @serverUpdateLog = new EnsimeServerUpdateLogView()
  # atom.workspace.addOpener (filePath) =>
  #   @serverUpdateLog if filePath is EnsimeServerUpdateLogView.URI

  # atom.workspace.open(EnsimeServerUpdateLogView.URI)

  pane = atom.workspace.getActivePane()
  pane.addItem @serverUpdateLog
  pane.activateItem @serverUpdateLog

  if not fs.existsSync(tempdir)
    fs.mkdirSync(tempdir)
    fs.mkdirSync(tempdir + '/project')

  # write out a build.sbt in this dir
  fs.writeFileSync(tempdir + '/build.sbt', createSbtStartScript(scalaVersion, ensimeServerVersion,
    classpathFile(scalaVersion, ensimeServerVersion)))

  fs.writeFileSync(tempdir + '/project/build.properties', 'sbt.version=0.13.8\n')

  cmd = atom.config.get('Ensime.sbtExec')
  console.log("sbt: " + cmd)

  # run sbt "saveClasspath" "clean"
  pid = spawn("#{atom.config.get('Ensime.sbtExec')}", ['-Dsbt.log.noformat=true', 'saveClasspath', 'clean'], {cwd: tempdir})
  pid.stdout.on 'data', (chunk) -> log(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) -> log('ensime startup exec error: ' + chunk.toString('utf8'))

  pid.stdout.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) => @serverUpdateLog.addRow('ensime startup exec error: ' + chunk.toString('utf8'))

  pid.stdin.end()


versions = ->
  ensimeConfigFile = projectPath() + '/.ensime'
  scalaVersion = scalaVersionOfProjectDotEnsime(ensimeConfigFile)
  ensimeServerVersion = atom.config.get('Ensime.ensimeServerVersion')
  {scalaVersion: scalaVersion, ensimeServerVersion: ensimeServerVersion}

classpathFileName = ->
  {s, e} = versions()
  classpathFile(s, e)

startEnsimeServer = (pidCallback) ->
  if not fs.existsSync(ensimeCache())
    fs.mkdirSync(ensimeCache())

  {scalaVersion, ensimeServerVersion} = versions()

  javaHome = atom.config.get('Ensime.JAVA_HOME')
  toolsJar = "#{javaHome}/lib/tools.jar"
  cpF = classpathFile(scalaVersion, ensimeServerVersion)
  log("classpathfile name: #{cpF}")

  if(not fs.existsSync(cpF))
    updateEnsimeServer(scalaVersion, ensimeServerVersion) # TODO async so wait for portfile


  checkForServerCP = (trysLeft) =>
    log("check for server classpath file #{cpF}. trys left: " + trysLeft)
    if(trysLeft == 0)
      modalMsg("Server hasn't been updated yet. If this is the first run, maybe you're downloading the internet. Check update
      log and try again!")
    else if not fs.existsSync(cpF)
        @serverUpdateTimeout = setTimeout (=>
          checkForServerCP(trysLeft - 1)
        ), 2000
    else
      # Classpath file for running Ensime server is in place
      classpath = toolsJar + ':' + fs.readFileSync(cpF, {encoding: 'utf8'})
      javaCmd = "#{javaHome}bin/java"
      ensimeServerFlags = "#{atom.config.get('Ensime.ensimeServerFlags')}"
      ensimeConfigFile = projectPath() + '/.ensime'
      args = ["-classpath", "#{classpath}", "-Densime.config=#{ensimeConfigFile}"]
      if ensimeServerFlags.length > 0
         args.push ensimeServerFlags  ## Weird, but extra " " broke everyting

      args.push "org.ensime.server.Server"


      log("Starting ensime server with: #{javaCmd} #{args.join(' ')}")



      serverLog = fs.createWriteStream(ensimeServerLogFile())

      pid = spawn(javaCmd, args, {
       detached: atom.config.get('Ensime.runServerDetached')
      })
      pid.stdout.pipe(serverLog) # TODO: have a screenbuffer tail -f this file.
      pid.stderr.pipe(serverLog)
      pid.stdin.end()
      pidCallback(pid)

  checkForServerCP(20) # 40 sec should be enough?











module.exports = {
  updateEnsimeServer: updateEnsimeServerManually,
  startEnsimeServer: startEnsimeServer,
  classpathFileName: classpathFileName
}
