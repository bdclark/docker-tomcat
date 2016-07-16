# steadyserv/tomcat-consul Docker Images

These images provide Apache Tomcat using the Oracle JDK, and configured by Consul.

## Environment variables
Use `TOMCAT_PREFIX` to set the key prefix where the tomcat configuration will be
found in Consul. If not set, `service/tomcat` will be used.

Also, you must set `CONSUL_HTTP_ADDR` in order for consul-template to render
any templates when the container runs. Any supported consul-template environment
variables can be used, such as:

- CONSUL_HTTP_ADDR
- CONSUL_HTTP_TOKEN
- CONSUL_HTTP_AUTH
- CONSUL_HTTP_SSL
- CONSUL_HTTP_SSL_VERIFY

## Supported Consul keys

setenv.sh settings            | description
------------------------------|-----------------------------------------------
`<prefix>/initial_heap_size`  | sets JVM `-Xms`
`<prefix>/max_heap_size`      | sets JVM `-Xmx`
`<prefix>/max_perm_size`      | sets JVM `-XX:MaxPermSize`
`<prefix>/debug/enabled`      | enable/disable debug on port `9981` (disabled by default)
`<prefix>/catalina_opts`      | additional space or linefeed delimited java options passed as `CATALINA_OPTS` to tomcat.

JMX settings                         | description
-------------------------------------|-----------------------------------------
`<prefix>/jmx/enabled`               | enable/disable JMX on port `9980` (disabled by default)
`<prefix>/jmx/users/<user>`          | usernames for JMX access
`<prefix>/jmx/users/<user>/access`   | `readonly` or `readwrite` access for JMX user
`<prefix>/jmx/users/<user>/password` | password for JMX user

tomcat-users.xml settings         | description
----------------------------------|-----------------------------------------
`<prefix>/roles`                  | comma-delimited list of roles in tomcat-users.xml
`<prefix>/users/<user>`           | username(s) in tomcat-users.xml
`<prefix>/users/<user>/password`  | password for tomcat user
`<prefix>/users/<user>/roles`     | comma-delimited list of roles for tomcat user

server.xml settings                   | description
--------------------------------------|---------------------------------------
`<prefix>/executor/<attribute>`       | attribute(s) for optional shared executor
`<prefix>/http_connector/<attribute>` | optional attribute(s) for HTTP connector on port `8080`
`<prefix>/engine_valves/<className>/<attribute>`  | optional map of engine valves
`<prefix>/host_valves/<className>/<attribute>`    | optional map of host valves

## Template rendering
When the container is launched, any file in the following directories ending with
`.ctmpl` will be rendered to a file with the same name with `.ctmpl` stripped:

- $CATALINA_BASE/conf/
- $CATALINA_BASE/lib/
- $CATALINA_BASE/bin/
- /entrypoint.d/

For example, `/var/lib/tomcat/conf/server.xml.ctmpl` will be rendered as
`/var/lib/tomcat/conf/server.xml`. Derived images can use this by adding additional
files in these directories, and expect them to be rendered at runtime.

## Entrypoint.d directory
The image's entrypoint script is configured to source any files contained in `/entrypoint.d`
immediately before starting tomcat. This can be used to execute basic scripts
added by derived images that might need to execute at runtime.

For example, a derived image could add a war file, and have an entrypoint script
explode the war and symlink a rendered property file somewhere within its
directory structure.
