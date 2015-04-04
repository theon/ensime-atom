{SwankParser} = require './swank-protocol'
{car, cdr, fromLisp} = require './lisp'
StatusbarView = require './statusbar-view'

if (typeof String::startsWith != 'function')
  String::startsWith = (str) ->
    return this.slice(0, str.length) == str


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
        @statusbarView.setText('Full typecheck finished!')

      else if(headStr == ':indexer-ready')
        @statusbarView.setText('indexer ready…')

      else if(headStr == ':clear-all-java-notes')
        @statusbarView.setText('feature todo: clear all java notes')

      else if(headStr == ':clear-all-scala-notes')
        @statusbarView.setText('feature todo: clear all scala notes')

      else if(headStr.startsWith(':background-message'))
        @statusbarView.setText("#{tail}")

      else if(headStr == ':scala-notes')
        @handleScalaNotes(tail)

    )


  ###
  (
  (:is-full nil :notes (
  (:severity error :msg "not found: value TakKey" :beg 123 :end 129 :line 8 :col 16 :file
  "/Users/viktor/dev/projects/sbt-gulp-task/src/main/scala/se/woodenstake/SbtGulpTask.scala"))
  ))
  ###
  sexpToJObject: (msg) ->
    arr = fromLisp(msg) # This arrayifies the lisp cons-list
    console.log("fromLisp: " + arr)

    parseObject = (sObjArr) ->
      if sObjArr.length == 0
        {}
      else
        keyValue = sObjArr.splice(0, 2)
        result = parseObject(sObjArr)
        value = keyValue[1]
        parsedValue = if Array.isArray(value) then parseArray(value) else value
        result[keyValue[0]] = parsedValue
        result

    parseArray = (sObjArr) ->
      (parseObject elem for elem in sObjArr)

    # An array with first element being ":label" is an object and an array of arrays is a real array
    firstElem = arr[0]
    if typeof firstElem is 'string' && firstElem.startsWith(":")
      # An object
      parseObject(arr)
    else
      parseArray(arr)


  handleScalaNotes: (msg) ->
    parsed = @sexpToJObject msg
    console.log("parsed notes: " + parsed)
    parsed

  handle: (msg) =>
    @parser.execute(msg)
