# atom-ensime

This is a work in progress to try to use [Ensime](https://github.com/ensime/) functionality in [Atom](https://atom.io)

## Prerequisites
- sbt (used to bootstrap server)
- .ensime file. generate with sbt gen-ensime https://github.com/ensime/ensime-server/wiki/Quick-Start-Guide#installing-the-ensime-sbt-plugin

## Features:
- [x] jump to definition (alt-click or f4)
- [x] hover for type info
- [x] get server "bundled" the same way Emacs does it
- [x] super basic errors and warnings
- [ ] better errors and warnings with markings in gutter
- [ ] errors on save or typing (currently only command)

- [ ] customizable key modifiers on mouse commands. cmd-click, ctrl-click or alt-click for go to definition?
- [ ] Try using code-links or their approach to make underlined links when hovering with cmd/ctrl
- [ ] autocompletion
- [ ] view applied implicits

## Dev
"Window: reload" (ctrl-option-cmd l) to reload plugin from source while developing

## Google group thread:
https://groups.google.com/forum/#!searchin/ensime/log/ensime/1dWUQwnFoyk/0O12KPjaIBgJ


## Technical TODO:
- [x] checkout typescript plugin for hover for type info
- [x] option to start server detached for ease of debugging: https://nodejs.org/api/child_process.html#child_process_options_detached
- [ ] server log in a panel in atom
- [ ] server will stop logging when atom is reloaded since stdio is piped via node. Pipe to file directly from process
 and tail -f to buffer in atom?
- [ ] seems I can have two clients attached to ensime server accidentaly.
- [ ] setting for typechecking current file: ask, on save, while typing + delay ms setting
- [ ] only try start server if no port-file
- [ ] getPath is deprecated: https://github.com/atom/atom/blob/master/src/project.coffee#L471 Maybe need to ask about where .ensime is like Emacs.
- [ ] add a bottom panel with tabs (one for errors/warnings, one for server log maybe)
- [ ] put console logging under dev-flag or just move to separate log
- [ ] Isolate swank/lisp - it leaks everywhere
- [ ] See if we can use code-links for mouse clicks https://atom.io/packages/code-links


## Inspiration (steal if you can)
- https://github.com/lukehoban/atom-ide-flow/
- code-links
- https://github.com/atom/atom/blob/master/src/text-editor-component.coffee#L365
- https://github.com/TypeStrong/atom-typescript/
- https://github.com/chaika2013/ide-haskell/

## Links
- https://github.com/ensime/
- Protocol: https://github.com/ensime/ensime-server/blob/master/swank/src/main/scala/org/ensime/server/protocol/swank/SwankProtocol.scala
- Emacs command ref: https://github.com/ensime/ensime-server/wiki/Emacs-Command-Reference
- Ensime google group: https://groups.google.com/forum/#!forum/ensime
- Startup of server from Emacs https://github.com/ensime/ensime-emacs/blob/master/ensime-startup.el
