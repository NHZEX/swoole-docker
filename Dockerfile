FROM php:7.2-cli

MAINTAINER au

LABEL product=swoole-server

ENV PHPREDIS_VER=4.3.0 SWOOLE_VER=4.3.5

# install modules : GD iconv gmp
# WARNING: Disable opcache-cli if you run you php
RUN apt-get update \
    && apt-get install -y procps \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libxpm-dev \
    libssh-dev libpcre3 libpcre3-dev libnghttp2-dev libhiredis-dev libgmp-dev \
    openssl curl wget zip unzip git \
    && apt autoremove \
    && apt clean \
    && docker-php-ext-configure gd --with-freetype-dir --with-jpeg-dir \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) iconv pdo_mysql mysqli mbstring json sockets pcntl gmp exif bcmath zip

#install redie
RUN set -x \
    && cd /tmp \
    && curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/${PHPREDIS_VER}.tar.gz \
    && mkdir -p /tmp/redis \
    && tar zxvf /tmp/redis.tar.gz -C redis --strip-components=1 && cd /tmp/redis \
    && phpize \
    && ./configure \
    && make -j$(nproc) && make install \
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
    && make -j$(nproc) && make install \
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

