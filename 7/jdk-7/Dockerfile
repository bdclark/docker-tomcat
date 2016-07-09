FROM steadyserv/oracle-jdk:1.7

RUN groupadd -r tomcat && useradd -mr -g tomcat tomcat

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME

# runtime dependencies for Tomcat Native Libraries
# Tomcat Native 1.2+ requires a newer version of OpenSSL than debian:jessie has available (1.0.2g+)
# see http://tomcat.10.x6.nabble.com/VOTE-Release-Apache-Tomcat-8-0-32-tp5046007p5046024.html (and following discussion)
ENV OPENSSL_VERSION 1.0.2h-1
RUN { \
		echo 'deb http://httpredir.debian.org/debian unstable main'; \
	} > /etc/apt/sources.list.d/unstable.list \
	&& { \
# add a negative "Pin-Priority" so that we never ever get packages from unstable unless we explicitly request them
		echo 'Package: *'; \
		echo 'Pin: release a=unstable'; \
		echo 'Pin-Priority: -10'; \
		echo; \
# except OpenSSL, which is the reason we're here
		echo 'Package: openssl libssl*'; \
		echo "Pin: version $OPENSSL_VERSION"; \
		echo 'Pin-Priority: 990'; \
	} > /etc/apt/preferences.d/unstable-openssl
RUN apt-get update && apt-get install -y --no-install-recommends \
		libapr1 \
		openssl="$OPENSSL_VERSION" \
	&& rm -rf /var/lib/apt/lists/*

ENV TOMCAT_VERSION 7.0.70

RUN set -x \
  && curl -fsL "https://repository.apache.org/content/repositories/releases/org/apache/tomcat/tomcat/$TOMCAT_VERSION/tomcat-$TOMCAT_VERSION.tar.gz" -o tomcat.tar.gz \
	&& tar xf tomcat.tar.gz --strip-components=1 \
  && rm tomcat.tar.gz \
	&& rm -rf bin/*.bat webapps/examples webapps/docs webapps/ROOT \
  && rm -rf webapps/manager webapps/host-manager \
  && mkdir conf/Catalina \
  \
	&& nativeBuildDir="$(mktemp -d)" \
	&& tar -xvf bin/tomcat-native.tar.gz -C "$nativeBuildDir" --strip-components=1 \
	&& nativeBuildDeps="gcc libapr1-dev libssl-dev make" \
	&& apt-get update && apt-get install -y --no-install-recommends $nativeBuildDeps && rm -rf /var/lib/apt/lists/* \
  && ( \
    cd "$nativeBuildDir/native" \
	  && ./configure \
		  --libdir=/usr/lib \
		  --with-apr=/usr/bin/apr-1-config \
		  --with-java-home="$JAVA_HOME" \
		  --with-ssl=yes \
	  && make -j$(nproc) \
	  && make install \
  ) \
	&& apt-get purge -y --auto-remove $nativeBuildDeps \
	&& rm -rf "$nativeBuildDir" \
	&& rm bin/tomcat-native.tar.gz

# verify Tomcat Native is working properly
RUN set -e \
	&& nativeLines="$(catalina.sh configtest 2>&1)" \
	&& nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')" \
	&& nativeLines="$(echo "$nativeLines" | sort -u)" \
	&& if ! echo "$nativeLines" | grep 'INFO: Loaded APR based Apache Tomcat Native library' >&2; then \
		echo >&2 "$nativeLines"; \
		exit 1; \
	fi

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

EXPOSE 8080

VOLUME ["$CATALINA_HOME/logs", "$CATALINA_HOME/webapps"]

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["catalina.sh", "run"]
