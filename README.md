# steadyserv/tomcat-consul Docker Images

These images provide Apache Tomcat using the Oracle JDK, and configured by Consul.

## Supported Consul Keys and Environment Variables
Use the `TOMCAT_PREFIX` environment variable to set the key prefix where the
tomcat configuration will be found in Consul. If not set, `service/tomcat`
will be used.

Also, you must set `CONSUL_HTTP_ADDR` in order for consul-template to render
any templates when the container runs. Any supported consul-template environment
variables can be used, such as:

- CONSUL_HTTP_ADDR
- CONSUL_HTTP_TOKEN
- CONSUL_HTTP_AUTH
- CONSUL_HTTP_SSL
- CONSUL_HTTP_SSL_VERIFY

#### Port Settings

Environment Variable  | Description             | Default
----------------------|-------------------------|--------
TOMCAT_HTTP_PORT      | HTTP connector port     | `8080`
TOMCAT_JMX_PORT       | JMX port (if enabled)   | `9080`
TOMCAT_DEBUG_PORT     | Debug port (if enabled) | `9180`

#### setenv.sh Settings

Consul Key                    | Environment Variable  | Description
------------------------------|-----------------------|-----------------------
`<prefix>/initial_heap_size`  | TOMCAT_HEAP_INITIAL   | sets JVM `-Xms`
`<prefix>/max_heap_size`      | TOMCAT_HEAP_MAX       | sets JVM `-Xmx`
`<prefix>/max_perm_size`      | TOMCAT_MAX_PERM_SIZE  | sets JVM `-XX:MaxPermSize`
`<prefix>/debug/enabled`      | TOMCAT_DEBUG_ENABLED  | enable/disable debug (disabled by default)
`<prefix>/jmx/enabled`        | TOMCAT_JMX_ENABLED    | enable/disable JMX (disabled by default)
`<prefix>/catalina_opts`      | CATALINA_OPTS         | additional space or linefeed delimited java options passed as `CATALINA_OPTS` to tomcat.

#### JMX Security Settings
The following setting are only relevant if JMX is enabled (see above). All settings
are optional, and have no defaults unless shown.

Consul Key                           | Environment Variable          | Description
-------------------------------------|-------------------------------|----------------------------------
`<prefix>/jmx/authenticate`          | TOMCAT_JMX_AUTHENTICATE       | whether JMX auth is enabled (default: `true`)
N/A                                  | TOMCAT_JMX_READONLY_USERNAME  | username for a JMX readonly user
N/A                                  | TOMCAT_JMX_READONLY_PASSWORD  | password for a JMX readonly user
N/A                                  | TOMCAT_JMX_READWRITE_USERNAME | username for a JMX readwrite user
N/A                                  | TOMCAT_JMX_READWRITE_PASSWORD | password for a JMX readwrite user
N/A                                  | TOMCAT_JMX_ACCESS_FILE        | path to JMX access file (default: `conf/jmxremote.access`)
N/A                                  | TOMCAT_JMX_PASSWORD_FILE      | path to JMX password file (default: `conf/jmxremote.password`)
`<prefix>/jmx/users/<user>/access`   | N/A                           | `readonly` or `readwrite` access for given JMX user
`<prefix>/jmx/users/<user>/password` | N/A                           | password for given JMX user

#### tomcat-users.xml Settings
The following Consul keys are optional and used to configure tomcat-users.xml.

Consul Key                        | Description
----------------------------------|-----------------------------------------
`<prefix>/roles`                  | comma-delimited list of roles in tomcat-users.xml
`<prefix>/users/<user>`           | username(s) in tomcat-users.xml
`<prefix>/users/<user>/password`  | password for tomcat user
`<prefix>/users/<user>/roles`     | comma-delimited list of roles for tomcat user

#### server.xml Settings

Consul Key                                       | Description
-------------------------------------------------|----------------------------
`<prefix>/executor/<attribute>`                  | attribute(s) for optional shared executor
`<prefix>/http_connector/<attribute>`            | optional attribute(s) for HTTP connector
`<prefix>/engine_valves/<className>/<attribute>` | optional map of engine valves
`<prefix>/host_valves/<className>/<attribute>`   | optional map of host valves

## Template rendering
When the container is launched, any file in the following directories ending with
`.ctmpl` will be rendered to a file with the same name with `.ctmpl` stripped:

- /entrypoint.d
- $CATALINA_HOME/conf
- $CATALINA_HOME/lib
- $CATALINA_HOME/bin
- $CATALINA_HOME/bin/setenv.d

For example, `/usr/local/tomcat/conf/server.xml.ctmpl` will be rendered as
`/usr/local/tomcat/conf/server.xml`. Derived images can use this by adding additional
files in these directories, and expect them to be rendered at runtime.

#### `bin/setenv.d` Directory
Rather than overwriting `bin/setenv.sh` in derived images, you can add additional
file(s) to `bin/setenv.d` and they will be sourced by the main setenv.sh script
at runtime.

#### `/entrypoint.d` Directory
The image's entrypoint script is configured to source any files contained in `/entrypoint.d`
immediately before starting tomcat. This can be used to execute basic scripts
added by derived images that might need to execute at runtime.

For example, a derived image could add a war file, and have an entrypoint script
explode the war and symlink a rendered property file somewhere within its
directory structure.
