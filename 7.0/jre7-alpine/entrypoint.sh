#!/usr/bin/dumb-init /bin/sh

export TOMCAT_PREFIX=${TOMCAT_PREFIX-service/tomcat}
export TOMCAT_HTTP_PORT=${TOMCAT_HTTP_PORT-8080}

: ${CONSUL_TEMPLATE_ACTION=once}

render_template() {
  if [ -d "$1" ]; then
    find $1 -maxdepth 1 -name "*.ctmpl" | while read file; do
      newfile="${file%.*}"
      if [ -f "$newfile" ]; then
        >&2 echo "File $newfile exists, not rendering $file"
      else
        >&2 echo "Rendering $file to $newfile"
        consul-template -once -template "${file}:${newfile}"
      fi
    done
  fi
}

if [ "$1" = "catalina.sh" ]; then
  # set CONSUL_HTTP_ADDR based on CONSUL_HOST:CONSUL_PORT
  if [ -n "$CONSUL_HOST" ]; then
    export CONSUL_HTTP_ADDR=${CONSUL_HOST}:${CONSUL_PORT-8500}
  fi

  if [ "$CONSUL_TEMPLATE_ACTION" = "once" ]; then
    if [ -n "$CONSUL_HTTP_ADDR" ]; then
      render_template /entrypoint.d
      render_template $CATALINA_HOME/bin
      render_template $CATALINA_HOME/bin/setenv.d
      render_template $CATALINA_HOME/conf
      render_template $CATALINA_HOME/lib
    else
      >&2 echo "Skipping consul-template... CONSUL_HOST or CONSUL_HTTP_ADDR not provided"
    fi

  elif [ "$CONSUL_TEMPLATE_ACTION" = "exec" ]; then
    >&2 echo "CONSUL_TEMPLATE_ACTION 'exec' mode not supported at this time"
    exit 1

  else
    >&2 echo "CONSUL_TEMPLATE_ACTION must be 'once' or 'exec'"
    exit 1
  fi

  # source files in /entrypoint.d
  if [ -d "/entrypoint.d" ]; then
    for file in /entrypoint.d/*; do
      >&2 echo "Sourcing ${file}..."
      . $file
    done
  fi

  cd $CATALINA_HOME || exit 1
  chown -R root:tomcat lib conf
  chown -R tomcat:tomcat temp work logs webapps
  # chown -R root:tomcat webapps
  # chmod g+s webapps
  find lib/ -type f -exec chmod 640 {} \;
  find conf/ -type f ! -name 'jmxremote.*' -exec chmod 640 {} \;
  chown -R tomcat:tomcat conf/jmxremote.* conf/Catalina
  chmod 400 conf/jmxremote.*

  exec su-exec tomcat "$@"
fi

exec "$@"
