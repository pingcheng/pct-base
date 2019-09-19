FROM php:7.3.9-fpm-alpine

ENV COMPOSER_ALLOW_SUPERUSER 1

RUN set -ex \
  	&& apk update \
    && apk add --no-cache git mysql-client curl openssh-client icu libpng freetype libjpeg-turbo postgresql-dev libffi-dev libsodium libzip-dev \
    && apk add --no-cache --virtual build-dependencies icu-dev libxml2-dev freetype-dev libpng-dev libjpeg-turbo-dev g++ make autoconf libsodium-dev \
    && apk add --no-cache nginx supervisor\
    && docker-php-source extract \
    && pecl install redis sodium \
    && docker-php-ext-enable redis sodium \
    && docker-php-source delete \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) pgsql pdo_mysql pdo_pgsql intl zip gd opcache \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && cd  / && rm -fr /src \
    && apk del build-dependencies \
    && rm -rf /tmp/* 

RUN sed -i 's,^user =.*$,user = root,' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's,^group =.*$,group = root,' /usr/local/etc/php-fpm.d/www.conf

RUN mkdir -p /run/nginx

ADD supervisor/supervisord.conf /etc/

CMD php-fpm -R