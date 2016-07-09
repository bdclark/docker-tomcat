#!/bin/bash
set -e

if [ "$1" = "catalina.sh" ]; then
  chown -R tomcat:tomcat "$CATALINA_HOME"
  exec gosu tomcat "$@"
fi

exec "$@"
