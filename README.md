# atom-ensime

This is a work in progress to try to use Ensime functionality in Atom.io


## Features:
- [x] jump to definition
- [x] key shortcuts
- [x] hover (or something) for type info
- [x] alt-click for jump to definition
- [ ] get server "bundled" the same way Emacs does it
- [ ] customizable commands
- [ ] customizable key modifiers on mouse commands. cmd-click, ctrl-click or alt-click for go to definition?
- [ ] Try using code-links or their approach to make underlined links when hovering with cmd/ctrl
- [ ] errors and warnings
- [ ] autocompletion
- [ ] view applied implicits

## Dev
"Window: reload" (ctrl-option-cmd l) to reload plugin from source while developing

## Google group thread:
https://groups.google.com/forum/#!searchin/ensime/log/ensime/1dWUQwnFoyk/0O12KPjaIBgJ


## Technical TODO:
- [x] checkout typescript plugin for hover for type info
- [ ] put console logging under dev-flag
- [ ] Isolate swank/lisp - it leaks everywhere
- [ ] See if we can use code-links for mouse clicks https://atom.io/packages/code-links


## Inspiration (steal if you can)
- https://github.com/lukehoban/atom-ide-flow/
- code-links
- https://github.com/atom/atom/blob/master/src/text-editor-component.coffee#L365
- https://github.com/TypeStrong/atom-typescript/
- https://github.com/chaika2013/ide-haskell/

## Links
- Protocol: https://github.com/ensime/ensime-server/blob/master/swank/src/main/scala/org/ensime/server/protocol/swank/SwankProtocol.scala
- Emacs command ref: https://github.com/ensime/ensime-server/wiki/Emacs-Command-Reference
- Ensime google group: https://groups.google.com/forum/#!forum/ensime
- Startup of server from Emacs https://github.com/ensime/ensime-emacs/blob/master/ensime-startup.el
