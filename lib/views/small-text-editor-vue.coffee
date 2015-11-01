Vue = require('vue')

module.exports = TextEditorVue = Vue.extend({
  template: """<atom-text-editor class="editor mini" tabindex="-1" mini="" data-grammar="text plain null-grammar" data-encoding="utf8"></atom-text-editor>"""
  methods:
    getTextEditor: () -> @$el.getModel()
  ready: () ->
    @$el.getModel().getBuffer().onDidChange =>
      @text = @$el.getModel().getBuffer().getText()
  props: ['text']

})
