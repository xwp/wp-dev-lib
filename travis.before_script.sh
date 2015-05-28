#!/bin/bash

set -e
shopt -s expand_aliases

# TODO: These should not override any existing environment variables
export WP_TESTS_DIR=/tmp/wordpress-tests/
export BUILD_TYPE=plugins
export BUILD_DIR=$(pwd)
export BUILD_SLUG=$(basename $(pwd) | sed 's/^wp-//')
export PHPCS_DIR=/tmp/phpcs
export PHPCS_GITHUB_SRC=squizlabs/PHP_CodeSniffer
export PHPCS_GIT_TREE=master
export PHPCS_IGNORE='tests/*,vendor/*,dev-lib/*'
export WPCS_DIR=/tmp/wpcs
export WPCS_GITHUB_SRC=WordPress-Coding-Standards/WordPress-Coding-Standards
export WPCS_GIT_TREE=master
export YUI_COMPRESSOR_CHECK=1
export DISALLOW_EXECUTE_BIT=0
export LIMIT_TRAVIS_PR_CHECK_SCOPE=files # when set to 'patches', limits reports to only lines changed; TRAVIS_PULL_REQUEST must not be 'false'
export PATH_INCLUDES=./
export WPCS_STANDARD=$(if [ -e phpcs.ruleset.xml ]; then echo phpcs.ruleset.xml; else echo WordPress-Core; fi)
if [ -e .jscsrc ]; then
	export JSCS_CONFIG=.jscsrc
elif [ -e .jscs.json ]; then
	export JSCS_CONFIG=.jscs.json
fi

# Load a .ci-env.sh to override the above environment variables
if [ -e .ci-env.sh ]; then
	source .ci-env.sh
fi

# Install the WordPress Unit Tests
if [ -e phpunit.xml ] || [ -e phpunit.xml.dist ]; then
	wget -O /tmp/install-wp-tests.sh https://raw.githubusercontent.com/wp-cli/wp-cli/v0.18.0/templates/install-wp-tests.sh
	bash /tmp/install-wp-tests.sh wordpress_test root '' localhost $WP_VERSION
	cd /tmp/wordpress/wp-content/$BUILD_TYPE
	mv $BUILD_DIR $BUILD_SLUG
	cd $BUILD_SLUG
	ln -s $(pwd) $BUILD_DIR
	echo "Location: $(pwd)"

	if ! command -v phpunit >/dev/null 2>&1; then
		wget -O /tmp/phpunit.phar https://phar.phpunit.de/phpunit.phar
		chmod +x /tmp/phpunit.phar
		alias phpunit='/tmp/phpunit.phar'
	fi
fi

# Install PHP_CodeSniffer and the WordPress Coding Standards
mkdir -p $PHPCS_DIR && curl -L https://github.com/$PHPCS_GITHUB_SRC/archive/$PHPCS_GIT_TREE.tar.gz | tar xvz --strip-components=1 -C $PHPCS_DIR
mkdir -p $WPCS_DIR && curl -L https://github.com/$WPCS_GITHUB_SRC/archive/$WPCS_GIT_TREE.tar.gz | tar xvz --strip-components=1 -C $WPCS_DIR
$PHPCS_DIR/scripts/phpcs --config-set installed_paths $WPCS_DIR

# Install JSHint
if ! command -v jshint >/dev/null 2>&1; then
	npm install -g jshint
fi

# Install jscs
if [ -n "$JSCS_CONFIG" ] && [ -e "$JSCS_CONFIG" ] && ! command -v jscs >/dev/null 2>&1; then
	npm install -g jscs
fi

# Install Composer
if [ -e composer.json ]; then
	wget http://getcomposer.org/composer.phar && php composer.phar install --dev
fi

set +e
