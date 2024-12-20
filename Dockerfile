ARG BASE_IMAGE=containers.internal/php-fpm-nginx:8.3

FROM alpine/git as prep

RUN git clone --depth 1 https://git.tt-rss.org/fox/tt-rss.git /tmp/ttrss/html

FROM $BASE_IMAGE

RUN apk add supervisor postgresql-dev icu-dev oniguruma-dev --no-cache

# enable the mcrypt module
#RUN docker-php-ext-install mcrypt \
RUN docker-php-ext-install pdo_mysql pgsql pdo_pgsql mbstring mysqli pcntl intl

# install ttrss and patch configuration
WORKDIR /var/www/html/ttrss
COPY --chown=82:82 --from=0 /tmp/ttrss/html /var/www/html/ttrss
RUN chown -R 82:82 /var/www/html/ttrss
RUN cp config.php-dist config.php

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

ENV TTRSS_PHP_EXECUTABLE /usr/local/bin/php

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD ttrss_files/configure-db.php /configure-db.php
ADD ttrss_files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf
