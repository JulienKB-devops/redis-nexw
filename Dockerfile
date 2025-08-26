# Pull base image.
FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get install -y --no-install-recommends
RUN apt-get install -y locales iputils-ping curl wget ca-certificates dpkg-dev gcc libc6-dev libssl-dev make tzdata

RUN rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN groupadd -r -g 999 redis && useradd -r -g redis -u 999 redis

# Install Redis.
COPY ./redis-stable.tar.gz /tmp/

RUN \
  cd /tmp && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  export BUILD_TLS=yes \
  make && \
  make install && \
  mkdir -p /etc/redis /var/log/redis && \
  cp -f *.conf /etc/redis && \
  rm -rf /tmp/redis-stable*

COPY ./redis.conf /etc/redis

# Define mountable directories.
RUN mkdir /data && chown redis:redis /data

VOLUME ["/data", "/etc/redis", "/var/log/redis"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["redis-server", "/etc/redis/redis.conf"]

# Expose ports.
EXPOSE 6379
