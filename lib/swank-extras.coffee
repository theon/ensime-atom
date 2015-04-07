{fromLisp} = require './lisp'


# Oh noes, this is crap, but fuck it and wait for json protocol
sexpToJObject = (msg) ->
  that = this
  arr = fromLisp(msg) # This arrayifies the lisp cons-list
  
  parseObject = (sObjArr) ->
    if sObjArr.length == 0
      {}
    else
      keyValue = sObjArr.splice(0, 2)
      result = parseObject(sObjArr)
      value = keyValue[1]
      parsedValue = if Array.isArray(value) then sexpToJObject(value) else value
      result[keyValue[0]] = parsedValue
      result

  parseArray = (sObjArr) ->
    (parseObject elem for elem in sObjArr)

  # An array with first element being ":label" is an object and an array of arrays is a real array, no?
  firstElem = arr[0]
  if typeof firstElem is 'string' && firstElem.startsWith(":")
    # An object
    parseObject(arr)
  else
    parseArray(arr)


module.exports =
  sexpToJObject: sexpToJObject
