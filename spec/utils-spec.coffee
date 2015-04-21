{formatSignature} = require '../lib/utils'

describe 'formatSignature', ->
  it "should format x, y -> z", ->
    inputParams = [[["x", "Int"], ["y", "Int"]]]



    result = formatSignature(inputParams)

    expect(result).toBe("${1:x: Int}, ${2:y: Int}")
