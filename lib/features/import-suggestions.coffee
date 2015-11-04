# Super quick one that just adds the first in list
# TODO: make ui for selecting

module.exports = class ImportSuggestions
  constructor: (@client) ->
    @refactorings = new (require('./refactorings'))(@client)

  getImportSuggestions: (buffer, pos, symbol) ->
    file = buffer.getPath()

    req =
      typehint: 'ImportSuggestionsReq'
      file: file
      point: pos
      names: [symbol]
      maxResults: 10

    @client.post(req, (res) =>
      @refactorings.prepareAddImport(res.symLists[0][0].name, file, (ref) =>
        if(ref.status == 'success')
          change = ref.changes[0] # TODO:
          @refactorings.performTextEdit(change, () =>
            console.log('performTextEdit callback')
            @refactorings.organizeImports(file, () =>
              console.log('organizeImports callback')
              @client.typecheckBuffer(buffer)
              )
            )
        else
          console.log('failed add import')
      )
    )
