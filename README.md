# Atom Ensime

This is a work in progress to try to use [Ensime](https://github.com/ensime/) functionality in [Atom](https://atom.io)
Way early still and will most likely be very buggy. Or maybe not start at all. The bootstrapping of the Ensime server might be an issue. Please let me know if you have any troubles with the few features implemented. I guess most problems will probably be related to bootstrapping of the Ensime server.

## Prerequisites
- sbt (used to bootstrap server)
- .ensime file. generate with sbt gen-ensime https://github.com/ensime/ensime-server/wiki/Quick-Start-Guide#installing-the-ensime-sbt-plugin

## Getting started
- Open a project with a .ensime in root
- Make sure to put path of sbt in settings.
- cmd-shift-P Ensime: Update server. This will use sbt to download all deps and create a classpath file for the server. Make take a while and currently no log output :)
- cmd-shift-P Ensime: Start server.
- cmd-shift-P Ensime: Init project. This will create a swank client and connect to the ensime server
- Then you can use the features marked x below :)

Note: Init project will start the server too, but need to check for portfile before

## Complementing packages:
- [Project manager](https://github.com/danielbrodin/atom-project-manager) is really handy to keep track of projects.
- Need plugin to navigate back to last cursor position when "code surfing". Maybe https://atom.io/packages/last-cursor-position

## Features:
- [x] Jump to definition (alt-click or f4)
- [x] Hover for type info
- [x] Errors and warnings (Ensime: typecheck file, typecheck buffer, typecheck all)
- [x] Typecheck while typing
- [x] Basic autocompletion
- [ ] Better errors and warnings with markings in gutter
- [ ] View applied implicits
- [ ] _insert your suggestion_


## Dev
- checkout from git straight into .atom/packages (or ln -s). Need to have the right name on the folder: "Ensime".
- run apm install
- "Window: reload" (ctrl-option-cmd l) to reload plugin from source while developing


## Google group thread:
https://groups.google.com/forum/#!searchin/ensime/log/ensime/1dWUQwnFoyk/0O12KPjaIBgJ


## Technical TODO:
- [x] checkout typescript plugin for hover for type info
- [x] option to start server detached for ease of debugging: https://nodejs.org/api/child_process.html#child_process_options_detached
- [x] update server log in a panel in atom (no copy paste though and terminal escape stuff)
- [x] Use port file to check for running server
- [x] Remove "start-server" and let init do it all
- [x] EditorControl leaks and keeps swank client on stop. Fix some cleanup!
- [x] Remove flowController-thing and look at Haskell IDE.
- [x] Make "start ensime" to start server(maybe) and client and "stop ensime" kill both
- [x] setting for typechecking current file: ask, on save, while typing + delay ms setting
- [x] only try start server if no port-file
- [x] put console logging under dev-flag or just move to separate log
- [x] Handle types of autocompletion. Weird swank?
- [x] TEEEESTS! Mostly because turnaround is killing me
- [x] re-insert activation events when this hits https://github.com/atom/settings-view/pull/371
- [x] Make update of server implicit from startup'
- [ ] Wait for analyzer ready msg - (:return (:abort 209 "Analyzer is not ready! Please wait.") 4)
- [ ] Setting for autocomplete - "excludeLowerPriority"
- [ ] Autocomplete: :type-sig (((("x" "Int") ("y" "Int"))) "Int")
- [ ] Separate each feature in own Editor Controller?
- [ ] server will stop logging when atom is reloaded since stdio is piped via node. Pipe to file directly from process
 and tail -f to buffer in atom?
- [ ] getPath is deprecated: https://github.com/atom/atom/blob/master/src/project.coffee#L471 Maybe need to ask about where .ensime is like Emacs.
- [ ] add a bottom panel with tabs (one for errors/warnings, one for server log maybe)
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
- Space pen https://github.com/atom/space-pen/blob/master/src/space-pen.coffee
- Space pen views https://github.com/atom/atom-space-pen-views/blob/master/src/scroll-view.coffee
- Find and replace:https://github.com/atom/find-and-replace/blob/master/lib/project/results-pane.coffee
