Vue = require('vue')

# TODO: extract component
TextEditorVue = Vue.extend({
  template: """<atom-text-editor class="editor mini" tabindex="-1" mini="" data-grammar="text plain null-grammar" data-encoding="utf8"></atom-text-editor>"""
  methods:
    getTextEditor: () -> @$el.getModel()
  ready: () ->
    @$el.getModel().getBuffer().onDidChange =>
      @text = @$el.getModel().getBuffer().getText()
  data: () ->
    text: ''
})

SymbolSearchVue = Vue.extend({
  # https://github.com/atom/atom/blob/master/src/text-editor-component.coffee
  template: """
    <div class="select-list fuzzy-finder">
      <small-text-editor v-ref:editor></small-text-editor>
      <ol class="list-group">
        <li class="two-lines" v-for="symbol in results" v-bind:class="{'selected': $index==selected}">
          <div class="primary-line file icon icon-file-text" data-name=".ctags" data-path=".ctags">{{symbol.localName}}</div>
          <div class="secondary-line path no-icon">{{symbol.name}}</div>
        </li>
      </ol>
    </div>
    """

  data: () ->
    results: []
    selected: 0

  components:
    'small-text-editor': TextEditorVue

  methods:
    onSearchTextUpdated: (callback) ->
      @watcher = @$refs.editor.$watch('text', callback)
      # TODO: kill of watcher when unmounted?

    focusSearchField: () ->
      @$refs.editor.$el.focus()

    getSelected: () ->
      @results[@selected]
})




module.exports = class SymbolSearchView
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

  cancel: () ->
    @modalPanel.hide()
