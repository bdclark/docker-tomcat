#!/bin/sh
#
# Sources all .sh files in bin/setenv.d
# Rather than overwriting this file, file(s) in that directory

for file in $CATALINA_HOME/bin/setenv.d/*.sh ; do
  if [ -f "$file" ] ; then
    if [ "$(tty)" != "not a tty" ]; then echo "Sourcing $file"; fi
    . "$file"
  fi
done
