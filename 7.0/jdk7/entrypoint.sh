#!/usr/bin/dumb-init /bin/bash

TOMCAT_CONFIG_KEY=${TOMCAT_CONFIG_KEY-service/tomcat}

render_template_dir() {
  find $1 -name "*.ctmpl" | while read file; do consul-template -once -template "$file:${file%.*}"; done
}

if [ -n "$CONSUL_HTTP_ADDR" ]; then
  render_template_dir $CATALINA_BASE/bin
  render_template_dir $CATALINA_BASE/conf
  render_template_dir $CATALINA_BASE/lib
  chmod 600 $CATALINA_BASE/conf/jmxremote.access $CATALINA_BASE/conf/jmxremote.password
  chown tomcat: $CATALINA_BASE/conf/jmxremote.access $CATALINA_BASE/conf/jmxremote.password
else
  >&2 echo "Skipping consul-template... CONSUL_HTTP_ADDR not provided"
fi

if [ "$1" = "catalina.sh" ]; then
  cd $CATALINA_BASE
  chown -R tomcat:tomcat temp work logs webapps
  # chown -R root:tomcat webapps
  # chmod g+s webapps
  find lib/ -type f -exec chmod 644 {} \;
  find conf/ -type f ! -name 'jmxremote.*' -exec chmod 644 {} \;
  chown tomcat:tomcat conf/Catalina
  exec gosu tomcat "$@"
fi

exec "$@"
