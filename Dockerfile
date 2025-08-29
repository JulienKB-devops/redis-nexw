# Pull base image.
FROM debian:bookworm-slim

# Install packages in a single layer with proper cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        pkg-config \
        wget \
        ca-certificates \
        dpkg-dev \
        gcc \
        g++ \
        libc6-dev \
        libssl-dev \
        make \
        tzdata \
        tcl && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.utf8

# Create redis user and group
RUN groupadd -r -g 999 redis && useradd -r -g redis -u 999 redis

# Install Redis.
COPY ./redis-stable.tar.gz /tmp/

RUN cd /tmp && \
    tar xvzf redis-stable.tar.gz && \
    cd redis-stable && \
    make BUILD_TLS=yes && \
    make install && \
    mkdir -p /etc/redis /var/log/redis && \
    cp redis.conf /etc/redis/ && \
    rm -rf /tmp/redis-stable*

COPY ./redis.conf /etc/redis

# Define mountable directories and set ownership
RUN mkdir /data && \
    chown redis:redis /data /etc/redis /var/log/redis

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD redis-cli ping || exit 1

# Define mountable directories.
VOLUME ["/data", "/etc/redis", "/var/log/redis"]

# Define working directory.
WORKDIR /data

# Switch to non-root user
USER redis

# Expose ports.
EXPOSE 6379

# Define default command.
CMD ["redis-server", "/etc/redis/redis.conf"]