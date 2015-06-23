{formatType, formatCompletionsSignature} = require '../lib/formatting'
{sexpToJObject, arrToJObject} = require '../lib/swank-extras'
{readFromString, fromLisp} = require '../lib/lisp'


resultTextToJs = (input) ->
  sexpToJObject(readFromString(input))[":return"][":ok"]

describe 'formatCompletionsSignature', ->
  it "should format x, y -> z", ->
    inputParams = [[["x", "Int"], ["y", "Int"]]]



    result = formatCompletionsSignature(inputParams)

    expect(result).toBe("${1:x: Int}, ${2:y: Int}")



  # 
  # "type": {
  #   "resultType": {
  #     "name": "String",
  #     "fullName": "java.lang.String",
  #     "typehint": "BasicTypeInfo",
  #     "typeId": 4,
  #     "typeArgs": [],
  #     "members": [],
  #     "declAs": {
  #       "typehint": "Class"
  #     }
  #   },
  #   "name": "(in: Array[Byte])String",
  #   "paramSections": [
  #     {
  #       "params": [
  #         [
  #           "in",
  #           {
  #             "name": "Array",
  #             "fullName": "scala.Array",
  #             "typehint": "BasicTypeInfo",
  #             "typeId": 1,
  #             "typeArgs": [
  #               {
  #                 "name": "Byte",
  #                 "fullName": "scala.Byte",
  #                 "typehint": "BasicTypeInfo",
  #                 "typeId": 2,
  #                 "typeArgs": [],
  #                 "members": [],
  #                 "declAs": {
  #                   "typehint": "Class"
  #                 }
  #               }
  #             ],
  #             "members": [],
  #             "declAs": {
  #               "typehint": "Class"
  #             }
  #           }
  #         ]
  #       ],
  #       "isImplicit": false
  #     }
  #   ],
  #   "typehint": "ArrowTypeInfo",
  #   "typeId": 3
  # }
  #
  #

describe 'formatType', ->
  it "should format simple type (scala.Int)", ->
    input = """
    (:return (:ok (:name "Int" :type-id 4 :full-name "scala.Int" :decl-as class :pos (:file "/Users/viktor/dev/projects/ensime-test-project/.ensime_cache/dep-src/source-jars/scala/Int.scala" :offset 994))) 95)
    """
    formatted = formatType(resultTextToJs(input))

    expect(formatted).toBe("scala.Int")


  it "should format arrow-type (Int.*)", ->
    input = """
    (:return (:ok (:name "(x: Int)Int" :type-id 68 :arrow-type t :result-type (:name "Int" :type-id 4 :full-name "scala.Int" :decl-as class) :param-sections ((:params (("x" (:name "Int" :type-id 4 :full-name "scala.Int" :decl-as class))))))) 97)
    """

    formatted = formatType(resultTextToJs(input))

    expect(formatted).toBe("(x: scala.Int): scala.Int")

  it "should parse curried arrow-type", ->
    input = """
    (:return (:ok (:name "(x: Int)(y: Int)Int" :type-id 3691 :arrow-type t :result-type (:name "Int" :type-id 4 :full-name "scala.Int" :decl-as class) :param-sections ((:params (("x" (:name "Int" :type-id 4 :full-name "scala.Int" :decl-as class)))) (:params (("y" (:name "Int" :type-id 4 :full-name "scala.Int" :decl-as class))))))) 192)
    """

    formatted = formatType(resultTextToJs(input))
    expect(formatted).toBe("(x: scala.Int)(y: scala.Int): scala.Int")


  it "should do something better with say Function1", ->
    input = """
    (:return (:ok (:name "Function1" :type-id 8 :full-name "scala.Function1" :decl-as trait :type-args ((:name "Int" :type-id 3 :full-name "scala.Int" :decl-as class) (:name "Int" :type-id 3 :full-name "scala.Int" :decl-as class)) :pos (:file "/Users/viktor/dev/projects/ensime-test-project/.ensime_cache/dep-src/source-jars/scala/Function1.scala" :offset 1349))) 51)
    """
    formatted = formatType(resultTextToJs(input))
    expect(formatted).toBe("scala.Function1[scala.Int, scala.Int]")
