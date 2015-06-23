

# This is the one returned from completions
formatCompletionsSignature = (paramLists) ->
  formatParamLists = (paramLists) ->
    formatParamList = (paramList) ->
      formatParam = (param, i) ->
        "${#{i}:#{param[0]}: #{param[1]}}"
      p = (formatParam(param, i+1) for param, i in paramList)
      p.join(", ")

    formattedParamLists = (formatParamList paramList for paramList in paramLists)
    formattedParamLists.join("|")
  if(paramLists)
    formatParamLists(paramLists)
  else
    ""




formatParam = (param) ->
  result = formatType(param[1])
  "#{param[0]}: #{result}"

formatParamSection = (paramSection) ->
  p = (formatParam(param) for param in paramSection.params)
  p.join(", ")

formatParamSections = (paramSections) ->
  sections = (formatParamSection(paramSection) for paramSection in paramSections)
  "(" + sections.join(")(") + ")"




# For hover
formatType = (theType) ->
  if(theType.typehint == "ArrowTypeInfo")
    formatParamSections(theType.paramSections) + ": " + formatType(theType.resultType)
  else if(theType.typehint == "BasicTypeInfo")
    typeArgs = theType.typeArgs
    if not typeArgs || typeArgs.length == 0
      theType.fullName
    else
      formattedTypeArgs = (formatType(typeArg) for typeArg in typeArgs).join(", ")
      theType.fullName + "[#{formattedTypeArgs}]"

module.exports = {
  formatCompletionsSignature,
  formatType
}
