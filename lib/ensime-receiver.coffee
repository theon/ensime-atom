{SwankParser} = require './swank-protocol'
{car, cdr, fromLisp} = require './lisp'
StatusbarView = require './statusbar-view'

if (typeof String::startsWith != 'function')
  String::startsWith = (str) ->
    return this.slice(0, str.length) == str

#:full-typecheck-finished


module.exports =
class EnsimeReceiver
  constructor: ->
    @statusbarView = new StatusbarView()
    @statusbarView.init()

    @parser = new SwankParser( (msg) =>
      console.log("Received from Ensime server: #{msg}")
      head = car(msg)
      tail = cdr(msg)
      headStr = head.toString()
      console.log("Head: #{head}")
      console.log("Tail: #{tail}")
      if(headStr == ':compiler-ready')
        @statusbarView.setText('compiler ready…')
      else if(headStr == ':full-typecheck-finished')
        @statusbarView.setText('full typecheck finished')
      else if(headStr == ':indexer-ready')
        @statusbarView.setText('indexer ready')
      else if(headStr == ':clear-all-java-notes')
        @statusbarView.setText('clear all java notes')
      else if(headStr == ':clear-all-scala-notes')
        @statusbarView.setText('indexer ready')
      else if(headStr.startsWith(':background-message'))
        @statusbarView.setText("#{tail}")
      else if(headStr == ':scala-notes')
        @handleScalaNotes(tail)

    )


  sexpToJObject: (msg) ->
    arr = fromLisp(msg)
    resultObject = {}
    currentRightSide = []

    handleElem(elem, i) ->
      if(elem.startsWith(":"))
        currentRightSide = []
        resultObject[elem] = currentRightSide

      else
        currentRightSide.push(elem)

    @handleElem(elem, i) for elem, i in arr
    resultObject


  ###
  (
  (:is-full nil :notes (
  (:severity error :msg "not found: value TakKey" :beg 123 :end 129 :line 8 :col 16 :file
  "/Users/viktor/dev/projects/sbt-gulp-task/src/main/scala/se/woodenstake/SbtGulpTask.scala"))
  ))
  ###
  handleScalaNotes: (msg) ->
    parsed = @sexpToJObject msg
    console.log("parsed notes: " + parsed)

  handle: (msg) =>
    @parser.execute(msg)
