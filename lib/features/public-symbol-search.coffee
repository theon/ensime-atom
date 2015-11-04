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
          @vue.results = msg.syms
          @vue.selected = 0
        )

    atom.commands.add @vue.$el,
      'core:move-up': (event) =>
        @vue.selected -= 1
        event.stopPropagation()

      'core:move-down': (event) =>
        @vue.selected += 1
        event.stopPropagation()

      'core:confirm': (event) =>
        selected = @vue.getSelected()
        if(selected)
          if(selected.pos)
            @client.goToPosition(selected.pos)
          else
            atom.notifications.addError("Got no position from Ensime server :(", {
              dismissable: true
              detail: "There was no .pos property of the the symbol from Ensime server. Maybe no source attached? Check .ensime!"
              })
          @toggle()
          event.stopPropagation()
        else
          # Do nothing


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
