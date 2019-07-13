FROM php:7.2-cli

MAINTAINER au

LABEL product=swoole-ops-server

ENV PHPREDIS_VER=4.3.0 SWOOLE_VER=4.3.5

# install modules : GD iconv gmp
RUN apt-get update && apt-get install -y \
    procps \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    openssl \
    libssh-dev \
    libpcre3 \
    libpcre3-dev \
    libnghttp2-dev \
    libhiredis-dev \
    libgmp-dev \
    curl \
    wget \
    zip \
    unzip \
    git && \
    apt autoremove && apt clean

# install php pdo_mysql opcache
# WARNING: Disable opcache-cli if you run you php
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install \
    iconv \
    gd \
    pdo_mysql \
    mysqli \
    iconv \
    mbstring \
    json \
    sockets \
    pcntl \
    gmp \
    exif \
    bcmath \
    zip

#install redie
RUN set -x \
    && cd /tmp \
    && curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/${PHPREDIS_VER}.tar.gz \
    && mkdir -p /tmp/redis \
    && tar zxvf /tmp/redis.tar.gz -C redis --strip-components=1 && cd /tmp/redis \
    && phpize \
    && ./configure \
    && make && make install \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/*

# install swoole
#TIP: it always get last stable version of swoole coroutine.
RUN set -x \
    && cd /tmp \
    && curl -L -o /tmp/swoole.tar.gz https://github.com/swoole/swoole-src/archive/v${SWOOLE_VER}.tar.gz \
    && mkdir -p /tmp/swoole \
    && tar zxvf /tmp/swoole.tar.gz -C swoole --strip-components=1 && cd /tmp/swoole \
    && phpize \
    && ./configure \
    --enable-openssl  \
    --enable-http2  \
    --enable-mysqlnd \
    --enable-sockets \
    && make && make install \
    && docker-php-ext-enable swoole \
    && rm -rf /tmp/*

# set China timezone
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    echo "[Date]\ndate.timezone=Asia/Shanghai" > /usr/local/etc/php/conf.d/timezone.ini

# install composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update --clean-backups
