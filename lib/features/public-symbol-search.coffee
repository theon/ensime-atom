SymbolSearchVue = require('../views/public-symbol-search-vue')

module.exports = class PublicSymbolSearch
  constructor: (@client) ->
    @vue = new SymbolSearchVue
    @element = document.createElement('div')
    @modalPanel = atom.workspace.addModalPanel
          item: @element, visible: false
    @vue.$mount(@element)

    @vue.onSearchTextUpdated (newText, oldText) =>
      req =
        typehint: "PublicSymbolSearchReq"
        keywords: newText.split(' ')
        maxResults: 10

      @client.post(req, (msg) =>
          console.log(msg)
          @vue.results = msg.syms
        )

  #  @filterEditorView.on 'blur', (e) =>
  #     @cancel() unless @cancelling


    atom.commands.add @vue.$el,
      'core:move-up': (event) =>
        @vue.selected -= 1
        event.stopPropagation()

      'core:move-down': (event) =>
        @vue.selected += 1
        event.stopPropagation()

      'core:confirm': (event) =>
        selected = @vue.getSelected()
        @client.goToPosition(selected.pos)
        @toggle()
        event.stopPropagation()

      'core:cancel': (event) =>
        @cancel()
        event.stopPropagation()

  toggle: () ->
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
      @vue.focusSearchField()
      @vue.se

  cancel: () ->
    @modalPanel.hide()
