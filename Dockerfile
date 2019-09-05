FROM php:7.2.22-cli-alpine3.10

MAINTAINER au

LABEL product=php-swoole-server

ENV PHPREDIS_VER=4.3.0 SWOOLE_VER=4.4.5

ARG CN="0"

# install modules
RUN set -eux \
    && ([ "${CN}" = "0" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories) \
    && apk --no-cache update \
    && apk add --no-cache freetype libpng libjpeg-turbo gmp openssl libssh libzip \
    && apk add --no-cache --virtual .fetch-dev freetype-dev libjpeg-turbo-dev libwebp-dev libxpm-dev gmp-dev openssl-dev \
    && apk add --no-cache --virtual .fetch-deps curl wget procps ${PHPIZE_DEPS} \
# install php modules
    && docker-php-source extract \
    && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/include --with-png-dir=/usr/include --with-xpm-dir=/usr/include \
    --with-webp-dir=/usr/include --with-freetype-dir=/usr/include \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) iconv pdo_mysql mysqli mbstring json sockets pcntl gmp exif bcmath zip \
    && docker-php-ext-enable sockets \
# compile php modules
    && mkdir -p /tmp/extend && cd /tmp/extend \
#install php redie
    && curl -L -o redis.tar.gz https://github.com/phpredis/phpredis/archive/${PHPREDIS_VER}.tar.gz \
    && mkdir redis && tar zxvf redis.tar.gz -C redis --strip-components=1 && cd redis \
    && phpize && ./configure \
    && make -j$(nproc) && make install \
    && docker-php-ext-enable redis \
    && cd /tmp/extend \
# install php swoole
    && curl -L -o swoole.tar.gz https://github.com/swoole/swoole-src/archive/v${SWOOLE_VER}.tar.gz \
    && mkdir swoole && tar zxvf swoole.tar.gz -C swoole --strip-components=1 && cd swoole \
    && phpize && ./configure \
    --enable-openssl  \
    --enable-http2  \
    --enable-mysqlnd \
    --enable-sockets \
    && make -j$(nproc) && make install \
# 保证启动顺序为最后一个
    && docker-php-ext-enable --ini-name z-php-ext-swoole.ini swoole \
# clear up
    && rm -rf /tmp/extend/* \
    && docker-php-source delete \
    && apk del --no-network .fetch-deps

# set China timezone
RUN apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# install composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update --clean-backups

