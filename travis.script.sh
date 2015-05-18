#!/bin/bash

set -e

find $PATH_INCLUDES -name '*.js'  | sed 's:^\.//*::' | sort > /tmp/included-js-files
find $PATH_INCLUDES -name '*.php' | sed 's:^\.//*::' | sort > /tmp/included-php-files

if [ "$TRAVIS_PULL_REQUEST" != 'false' ] && [ "$LIMIT_TRAVIS_PR_CHECK_SCOPE" != '0' ]; then
	git diff --diff-filter=AM --name-only $TRAVIS_BRANCH...$TRAVIS_COMMIT | grep -E '\.php$' | cat - | sort > /tmp/changed-php-files
	git diff --diff-filter=AM --name-only $TRAVIS_BRANCH...$TRAVIS_COMMIT | grep -E '\.js$' | cat - | sort > /tmp/changed-js-files

	comm -12 /tmp/included-php-files /tmp/changed-php-files > /tmp/checked-php-files
	comm -12 /tmp/included-js-files /tmp/changed-js-files > /tmp/checked-js-files
else
	cp /tmp/included-js-files /tmp/checked-js-files
	cp /tmp/included-php-files /tmp/checked-php-files
fi

echo "TRAVIS_BRANCH: $TRAVIS_BRANCH"
echo "PHP Files to check:"
cat /tmp/checked-php-files
echo

echo "JS Files to check:"
cat /tmp/checked-js-files
echo

# Run PHP syntax check
cat /tmp/checked-php-files | xargs --no-run-if-empty php -lf

# Run JSHint
cat /tmp/checked-js-files | xargs --no-run-if-empty jshint $( if [ -e .jshintignore ]; then echo "--exclude-path .jshintignore"; fi )

# Run JSCS
if [ -n "$JSCS_CONFIG" ] && [ -e "$JSCS_CONFIG" ]; then
	cat /tmp/checked-js-files | xargs --no-run-if-empty jscs --verbose --config="$JSCS_CONFIG"
fi

# Run PHP_CodeSniffer
cat /tmp/checked-php-files | xargs --no-run-if-empty $PHPCS_DIR/scripts/phpcs -s --standard=$WPCS_STANDARD $(if [ -n "$PHPCS_IGNORE" ]; then echo --ignore=$PHPCS_IGNORE; fi)

# Run PHPUnit tests
if [ -e phpunit.xml ] || [ -e phpunit.xml.dist ]; then
	phpunit $( if [ -e .coveralls.yml ]; then echo --coverage-clover build/logs/clover.xml; fi )
fi

# Run YUI Compressor Check
if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && [ 0 != $( cat /tmp/checked-js-files | wc -l ) ]; then
	YUI_COMPRESSOR_PATH=/tmp/yuicompressor-2.4.8.jar
	wget -O "$YUI_COMPRESSOR_PATH" https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar
	cat /tmp/checked-js-files | xargs --no-run-if-empty java -jar "$YUI_COMPRESSOR_PATH" -o /dev/null 2>&1
fi
