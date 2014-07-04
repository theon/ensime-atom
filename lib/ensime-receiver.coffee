{SwankParser} = require './swank-protocol'
{car, cdr} = require './lisp'
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
      head = car(msg)
      headStr = head.toString()
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
        @statusbarView.setText('background message')
    )

  handle: (msg) =>
    @parser.execute(msg)
