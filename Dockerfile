FROM php:7.4.13-cli-alpine

MAINTAINER auooru

LABEL product=php-swoole-server

ENV PHPREDIS_VER=5.3.2 SWOOLE_VER=4.5.10

ARG CN="0"

# default installed: ctype curl date dom fileinfo filter ftp hash iconv json libxml mbstring openssl
#                  : pcre PDO pdo_splite Phar posix readline Reflection session SimpleXML sodium SPL
#                  : sqlite3 standard tokenizer xml xmlreader xmlwriter zlib

# install modules
RUN set -eux \
    && ([ "${CN}" = "0" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories) \
    && apk --no-cache update \
    && apk add --no-cache --virtual .fetch-deps curl wget procps ${PHPIZE_DEPS} \
    && apk add --no-cache libstdc++ freetype libpng libjpeg-turbo gmp openssl libssh libzip \
    && apk add --no-cache --virtual .fetch-dev freetype-dev libjpeg-turbo-dev libwebp-dev libxpm-dev gmp-dev openssl-dev zlib-dev libzip-dev \
# install php modules
    && docker-php-source extract \
    && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/include --with-png-dir=/usr/include --with-xpm-dir=/usr/include \
    --with-webp-dir=/usr/include --with-freetype-dir=/usr/include \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo_mysql mysqli sockets pcntl gmp exif bcmath zip \
# compile php modules
    && cd /usr/src/php/ext \
# install php redie
    && pecl install redis-${PHPREDIS_VER} \
    && docker-php-ext-enable redis \
# install php swoole
    && pecl bundle swoole-${SWOOLE_VER} \
    && docker-php-ext-configure swoole \
     --enable-openssl \
     --enable-http2 \
     --enable-swoole-json \
    && docker-php-ext-install -j$(nproc) swoole \
# clear up
    && docker-php-source delete \
    && apk del --no-network .fetch-deps \
    && php -v \
    && php -m

# set China timezone
RUN apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# install composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update --clean-backups

