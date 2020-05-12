ARG WP_PHP_VERSION=7.4
FROM wordpress:php${WP_PHP_VERSION}-fpm

ENV DEBIAN_FRONTEND noninteractive

# Development tooling dependencies.
RUN apt-get update \
	&& apt-get install --yes --no-install-recommends \
		bash less subversion default-mysql-server default-mysql-client libxml2-utils rsync git zip unzip \
		nodejs npm curl \
	&& npm install --global npm@latest \
	&& rm -rf /var/lib/apt/lists/

# Setup xdebug.
RUN	pecl install xdebug \
	&& docker-php-ext-enable xdebug

# Install Composer.
RUN curl -s https://getcomposer.org/installer | php \
	&& mv composer.phar /usr/local/bin/composer

# Keep a copy of our default test config.
COPY config/wp-tests-config.php /tmp/wp-dev-lib/wp-tests-config.php

# Setup a custom entrypoint that bootstraps the environment.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

VOLUME /tmp/wordpress

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["php-fpm"]
