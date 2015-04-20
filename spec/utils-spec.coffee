{formatSignature} = require '../lib/utils'

describe 'formatSignature', ->
  it "should format x, y -> z", ->
    inputParams = [[["x", "Int"], ["y", "Int"]]]



    result = formatSignature(inputParams, "Int")

    expect(result).toBe("x: Int, y: Int -> Int")
