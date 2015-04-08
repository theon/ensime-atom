# Download and startup of ensime server
fs = require('fs')
{sexpToJObject} = require('./swank-extras')
{exec, spawn} = require('child_process')
lisp = require('./lisp')
{log} = require('./utils')

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
  atom.packages.resolvePackagePath('Ensime') + "/classpath_#{scalaVersion}_#{ensimeServerVersion}"

ensimeConfigFile = atom.project.getPath() + '/.ensime'
ensimeCache = atom.project.getPath() + '/.ensime_cache'
ensimeServerLogFile = ensimeCache + '/server.log'

readDotEnsime = -> # TODO: error handling
  raw = fs.readFileSync(ensimeConfigFile) # TODO: ask as Emacs?
  rows = raw.toString().split(/\r?\n/);
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')


scalaVersionOfProjectDotEnsime = ->
  # scala version from .ensime config file of project
  dotEnsime = readDotEnsime()
  dotEnsimeLisp = lisp.readFromString(dotEnsime)
  dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
  dotEnsimeJs[':scala-version']

updateEnsimeServer = ->
  # createTempDir plugindir + ensime_update_
  dir = tempdir

  fs.exists(dir, (exists) =>
    if not exists
      fs.mkdirSync(dir)
      fs.mkdirSync(dir + '/project')
  )

  ensimeServerVersion = atom.config.get('ensime.ensimeServerVersion')


  scalaVersion = scalaVersionOfProjectDotEnsime()

  # write out a build.sbt in this dir
  fs.writeFileSync(tempdir + '/build.sbt', createSbtStartScript(scalaVersion, ensimeServerVersion,
    classpathFile(scalaVersion, ensimeServerVersion)))


  fs.writeFileSync(tempdir + '/project/build.properties', 'sbt.version=0.13.8\n')

  # if file exist classpathFile delete

  # run sbt "saveClasspath" "clean"
  pid = spawn("#{atom.config.get('ensime.sbtExec')}", ['saveClasspath', 'clean'], {cwd: tempdir})
  pid.stdout.on 'data', (chunk) -> log(chunk.toString('utf8'))
  pid.stderr.on 'data', (chunk) -> log('ensime startup exec error: ' + chunk.toString('utf8'))
  pid.stdin.end()


startEnsimeServer = ->
  javaHome = atom.config.get('ensime.JAVA_HOME')
  toolsJar = "#{javaHome}/lib/tools.jar"
  scalaVersion = scalaVersionOfProjectDotEnsime()
  ensimeServerVersion = atom.config.get('ensime.ensimeServerVersion')

  classpathFileName = classpathFile(scalaVersion, ensimeServerVersion)
  #if(not fs.existsSync(path))
  # updateEnsimeServer() # TODO: make parameters and remove update from commands
    # TODO: Oh, updateEnsimeServer is still async…

  classpath = toolsJar + ':' + fs.readFileSync(classpathFileName, {encoding: 'utf8'})

  javaCmd = "#{javaHome}bin/java"
  ensimeServerFlags = "#{atom.config.get('ensime.ensimeServerFlags')}"
  args = ["-classpath", "#{classpath}", "-Densime.config=#{ensimeConfigFile}"]
  if ensimeServerFlags.length > 0
     args.push ensimeServerFlags  ## Weird, but extra " " broke everyting

  args.push "org.ensime.server.Server"


  log("Starting ensime server with: #{javaCmd} #{args.join(' ')}")


  serverLog = fs.createWriteStream(ensimeServerLogFile)

  pid = spawn(javaCmd, args)
  pid.stdout.pipe(serverLog) # TODO: have a screenbuffer tail -f this file.
  pid.stderr.pipe(serverLog)
  pid.stdin.end()
  pid



module.exports = {
  updateEnsimeServer: updateEnsimeServer,
  startEnsimeServer: startEnsimeServer
}
