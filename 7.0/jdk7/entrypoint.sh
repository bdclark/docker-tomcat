#!/usr/bin/dumb-init /bin/bash

export TOMCAT_PREFIX=${TOMCAT_PREFIX-service/tomcat}

render_template_dir() {
  if [ -d "$1" ]; then
    find $1 -name "*.ctmpl" | while read file; do
      >&2 echo "Rendering $file to ${file%.*}..."
      consul-template -once -template "$file:${file%.*}";
    done
  fi
}

if [ "$1" = "catalina.sh" ]; then
  if [ -n "$CONSUL_HOST" ]; then
    CONSUL_HTTP_ADDR=${CONSUL_HOST}:${CONSUL_PORT-8500}
  fi

  if [ -n "$CONSUL_HTTP_ADDR" ]; then
    render_template_dir /entrypoint.d
    render_template_dir $CATALINA_BASE/bin
    render_template_dir $CATALINA_BASE/conf
    render_template_dir $CATALINA_BASE/lib
    chmod 600 $CATALINA_BASE/conf/jmxremote.access $CATALINA_BASE/conf/jmxremote.password
    chown tomcat: $CATALINA_BASE/conf/jmxremote.access $CATALINA_BASE/conf/jmxremote.password
  else
    >&2 echo "Skipping consul-template... CONSUL_HOST or CONSUL_HTTP_ADDR not provided"
  fi

  if [ -d "/entrypoint.d" ]; then
    for f in /entrypoint.d/*; do
      >&2 echo "Sourcing $f..."
      source $f
    done
  fi

  cd $CATALINA_BASE || exit 1
  chown -R tomcat:tomcat temp work logs webapps
  # chown -R root:tomcat webapps
  # chmod g+s webapps
  find lib/ -type f -exec chmod 644 {} \;
  find conf/ -type f ! -name 'jmxremote.*' -exec chmod 644 {} \;
  chown tomcat:tomcat conf/Catalina

  exec gosu tomcat "$@"
fi

exec "$@"
