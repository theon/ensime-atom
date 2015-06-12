

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
  p = (formatParam(param) for param in paramSection[":params"])
  p.join(", ")

formatParamSections = (paramSections) ->
  sections = (formatParamSection(paramSection) for paramSection in paramSections)
  "(" + sections.join(")(") + ")"

# For hover
formatType = (theType) ->
  if(theType[":arrow-type"])
    formatParamSections(theType[":param-sections"]) + ": " + formatType(theType[":result-type"])
  else
    typeArgs = theType[":type-args"]
    if not typeArgs
      theType[":full-name"]
    else
      formattedTypeArgs = (formatType(typeArg) for typeArg in typeArgs).join(", ")
      theType[":full-name"] + "[#{formattedTypeArgs}]"

module.exports = {
  formatCompletionsSignature,
  formatType
}
