# atom-ensime

This is a work in progress to try to use Ensime functionality in Atom.io

1. sbt ensime (to generate .ensime file)
2. cmd-shift-P Ensime: start server (if developing, start manually with .sh instead to see log in stdout (note: working dir))

    ~/dev/projects/ensime-src/dist $ 2.11/bin/server ~/dev/projects/kostbevakningen/ensime_port

3. Ensime: init project


"Window: reload" to reload plugin from source while developing

## Google group thread:
https://groups.google.com/forum/#!searchin/ensime/log/ensime/1dWUQwnFoyk/0O12KPjaIBgJ


## Features TODO:
* go to definition
* hover (or something) for type info
* error reporting
* view applied implicits

## DONE:
