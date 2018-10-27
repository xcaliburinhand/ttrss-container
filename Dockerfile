FROM alpine/git as prep

RUN git clone --depth 1 https://tt-rss.org/gitlab/fox/tt-rss.git /tmp/ttrss/html

FROM containers.internal/php-fpm-nginx

RUN apk add supervisor postgresql-dev --no-cache

# enable the mcrypt module
#RUN docker-php-ext-install mcrypt \
RUN docker-php-ext-install pdo_mysql \
    && docker-php-ext-install pgsql pdo_pgsql \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install pcntl

# install ttrss and patch configuration
WORKDIR /var/www/html/ttrss
COPY --from=0 --chown=www-data:www-data /tmp/ttrss/html /var/www/html/ttrss
RUN cp config.php-dist config.php

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD ttrss_files/configure-db.php /configure-db.php
ADD ttrss_files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf