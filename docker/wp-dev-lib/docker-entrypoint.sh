#!/bin/bash

set -ex

export WP_CORE_DIR="${WP_CORE_DIR:-/tmp/wordpress}"
export WP_TESTS_DIR="${WP_TESTS_DIR:-$WP_CORE_DIR/tests/phpunit}"
export WP_SVN_URL="${WP_SVN_URL:-https://develop.svn.wordpress.org/trunk/}"

# Start the MySQL server.
service mysql start

# Ensure we have a password and a fresh database.
# TODO Figure out the ERROR 1045 (28000) error because of the password change.
# TODO Allow custom test DB content.
mysql --user=root --password=root << END
	DROP DATABASE IF EXISTS wordpress_test;
	CREATE DATABASE wordpress_test;
	SET PASSWORD = PASSWORD('root');
	GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
	FLUSH PRIVILEGES;
END

# Ensure we have the WP core files.
if [ ! -d /tmp/wordpress/tests ]; then
	svn export --force "$WP_SVN_URL" /tmp/wordpress
fi

# Ensure we have a config file to work with.
if [ ! -f /tmp/wordpress/wp-tests-config.php ]; then
	cp /tmp/wp-dev-lib/wp-tests-config.php /tmp/wordpress/wp-tests-config.php
fi

# Run the command passed to this container.
exec "$@"
