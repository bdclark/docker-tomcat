#!/bin/bash
set -e

if [ "$1" = "catalina.sh" ]; then
  chown -R tomcat:tomcat "$CATALINA_BASE"
  exec gosu tomcat "$@"
fi

exec "$@"
