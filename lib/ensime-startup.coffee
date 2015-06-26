# Download and startup of ensime server
fs = require('fs')
path = require('path')
{exec, spawn} = require('child_process')
{log, modalMsg, projectPath} = require('./utils')
EnsimeServerUpdateLogView = require('./views/ensime-server-update-log-view')
lisp = require './lisp/lisp'
{sexpToJObject} = require './lisp/swank-extras'
remote = require 'remote'


createSbtClasspathBuild = (scalaVersion, ensimeServerVersion, classpathFile) ->
  """
  import sbt._

  import IO._

  import java.io._

  scalaVersion := \"#{scalaVersion}\"

  // allows local builds of scala
  resolvers += Resolver.mavenLocal

  ivyScala := ivyScala.value map { _.copy(overrideScalaVersion = true) }

  resolvers += Resolver.sonatypeRepo(\"snapshots\")

  resolvers += \"Typesafe repository\" at \"http://repo.typesafe.com/typesafe/releases/\"

  resolvers += \"Akka Repo\" at \"http://repo.akka.io/repository\"

  libraryDependencies ++= Seq(
    \"org.ensime\" %% \"ensime\" % \"#{ensimeServerVersion}\",
    \"org.scala-lang\" % \"scala-compiler\" % scalaVersion.value force(),
    \"org.scala-lang\" % \"scala-reflect\" % scalaVersion.value force(),
    \"org.scala-lang\" % \"scalap\" % scalaVersion.value force()
  )

  val saveClasspathTask = TaskKey[Unit](\"saveClasspath\", \"Save the classpath to a file\")

  saveClasspathTask := {
    val managed = (managedClasspath in Runtime).value.map(_.data.getAbsolutePath)
    val unmanaged = (unmanagedClasspath in Runtime).value.map(_.data.getAbsolutePath)
    val out = file(\"""#{classpathFile}\""")
    write(out, (unmanaged ++ managed).mkString(File.pathSeparator))
  }
  """

packageDir = atom.packages.resolvePackagePath('Ensime')
tempdir =  packageDir + "/ensime_update_"


classpathFile = (scalaVersion, ensimeServerVersion) ->
  atom.packages.resolvePackagePath('Ensime') + path.sep + "classpath_#{scalaVersion}_#{ensimeServerVersion}"


ensimeCache = -> projectPath() + path.sep + '.ensime_cache'
ensimeServerLogFile = -> ensimeCache() + path.sep + 'server.log'

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
  ensimeConfigFile = projectPath() + path.sep '.ensime'
  scalaVersion = scalaVersionOfProjectDotEnsime(ensimeConfigFile)
  ensimeServerVersion = atom.config.get('Ensime.ensimeServerVersion')
  if not (projectPath() and fs.existsSync(ensimeConfigFile))
    modalMsg('No .ensime found', "You need to have a project open with a .ensime in root.")
  else
    updateEnsimeServer(scalaVersion, ensimeServerVersion)


updateEnsimeServer = (sbtCmd, scalaVersion, ensimeServerVersion) ->
  @serverUpdateLog = new EnsimeServerUpdateLogView()

  pane = atom.workspace.getActivePane()
  pane.addItem @serverUpdateLog
  pane.activateItem @serverUpdateLog

  if not fs.existsSync(tempdir)
    fs.mkdirSync(tempdir)
    fs.mkdirSync(tempdir + path.sep + 'project')

  # write out a build.sbt in this dir
  fs.writeFileSync(tempdir + path.sep + 'build.sbt', createSbtClasspathBuild(scalaVersion, ensimeServerVersion,
    classpathFile(scalaVersion, ensimeServerVersion)))

  fs.writeFileSync(tempdir + path.sep + 'project' + path.sep + 'build.properties', 'sbt.version=0.13.8\n')

  # run sbt "saveClasspath" "clean"
  pid = spawn("#{sbtCmd}", ['-Dsbt.log.noformat=true', 'saveClasspath', 'clean'], {cwd: tempdir})
  pid.stdout.on 'data', (chunk) -> log(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) -> log(chunk.toString('utf8'))
  pid.stdout.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) => @serverUpdateLog.addRow(chunk.toString('utf8'))
  pid.stdin.end()


versions = ->
  ensimeConfigFile = projectPath() + path.sep + '.ensime'
  scalaVersion = scalaVersionOfProjectDotEnsime(ensimeConfigFile)
  ensimeServerVersion = atom.config.get('Ensime.ensimeServerVersion')
  {scalaVersion: scalaVersion, ensimeServerVersion: ensimeServerVersion}

classpathFileName = ->
  {s, e} = versions()
  classpathFile(s, e)


# Check that we have a classpath that is newer than atom ensime package.json (updated on release), otherwise delete it
classpathFileOk = (cpF) ->
  if not fs.existsSync(cpF)
    false
  else
    cpFStats = fs.statSync(cpF)
    fine = cpFStats.isFile && cpFStats.ctime > fs.statSync(packageDir + path.sep + 'package.json').mtime
    if not fine
      fs.unlinkSync(cpF)
    fine


withJavaHome = (callback) =>
  javaHome = atom.config.get('Ensime.JAVA_HOME')
  if javaHome
    callback(javaHome)
  else
    if process.env.JAVA_HOME
      javaHome = process.env.JAVA_HOME
      atom.config.set('Ensime.JAVA_HOME', javaHome)
      callback(javaHome)
    else
      dialog = remote.require('dialog')
      dialog.showOpenDialog({title: "So sorry, but please select your JAVA_HOME", properties:['openDirectory']}, (filenames) =>
          javaHome = filenames[0]
          atom.config.set('Ensime.JAVA_HOME', javaHome)
          callback(javaHome)
        )

withSbt = (callback) =>
  sbtCmd = atom.config.get('Ensime.sbtExec')
  if sbtCmd
    callback(sbtCmd)
  else
    dialog = remote.require('dialog')
    dialog.showOpenDialog({title: "Sorry, but we need you to point out your SBT executive", properties:['openFile']}, (filenames) =>
        sbtCmd = filenames[0]
        atom.config.set('Ensime.sbtExec', sbtCmd)
        callback(sbtCmd)
      )


startEnsimeServer = (pidCallback) ->
  withJavaHome (javaHome) =>
    if not fs.existsSync(ensimeCache())
      fs.mkdirSync(ensimeCache())

    {scalaVersion, ensimeServerVersion} = versions()

    toolsJar = "#{javaHome}#{path.sep}lib#{path.sep}tools.jar"
    cpF = classpathFile(scalaVersion, ensimeServerVersion)
    log("classpathfile name: #{cpF}")

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
        javaCmd = "#{javaHome}#{path.sep}bin#{path.sep}java"
        ensimeServerFlags = "#{atom.config.get('Ensime.ensimeServerFlags')}"
        ensimeConfigFile = projectPath() + path.sep + '.ensime'
        args = ["-classpath", "#{classpath}", "-Densime.config=#{ensimeConfigFile}", "-Densime.protocol=jerk"]
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


    if(not classpathFileOk(cpF))
      withSbt (sbtCmd) =>
        updateEnsimeServer(sbtCmd, scalaVersion, ensimeServerVersion)
        checkForServerCP(20) # 40 sec should be enough?
    else
      checkForServerCP(20) # 40 sec should be enough?






module.exports = {
  updateEnsimeServer: updateEnsimeServerManually,
  startEnsimeServer: startEnsimeServer,
  classpathFileName: classpathFileName
}
