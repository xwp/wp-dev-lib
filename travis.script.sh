#!/bin/bash

set -e

find $PATH_INCLUDES -type f | sed 's:^\.//*::' | sort > /tmp/included-files

if [ "$TRAVIS_PULL_REQUEST" != 'false' ] && [ "$LIMIT_TRAVIS_PR_CHECK_SCOPE" != '0' ]; then
	git diff --diff-filter=AM --name-only $TRAVIS_BRANCH...$TRAVIS_COMMIT | cat - | sort > /tmp/changed-files

	comm -12 /tmp/included-files /tmp/changed-files > /tmp/checked-files
else
	cp /tmp/included-files /tmp/checked-files
fi

echo "TRAVIS_BRANCH: $TRAVIS_BRANCH"
echo "Files to check:"
cat /tmp/checked-files
echo

# Run PHP syntax check
cat /tmp/checked-files | grep '.php' | xargs --no-run-if-empty php -lf

# Run JSHint
# TODO: Restrict to lines changed
cat /tmp/checked-files | grep '.js' | xargs --no-run-if-empty jshint $( if [ -e .jshintignore ]; then echo "--exclude-path .jshintignore"; fi )

# Run JSCS
if [ -n "$JSCS_CONFIG" ] && [ -e "$JSCS_CONFIG" ]; then
	# TODO: Restrict to lines changed
	cat /tmp/checked-files | grep '.js' | xargs --no-run-if-empty jscs --verbose --config="$JSCS_CONFIG"
fi

# Run PHP_CodeSniffer
# TODO: Restrict to lines changed
cat /tmp/checked-files | grep '.php' | xargs --no-run-if-empty $PHPCS_DIR/scripts/phpcs -s --standard=$WPCS_STANDARD $(if [ -n "$PHPCS_IGNORE" ]; then echo --ignore=$PHPCS_IGNORE; fi)

# Run PHPUnit tests
if [ -e phpunit.xml ] || [ -e phpunit.xml.dist ]; then
	phpunit $( if [ -e .coveralls.yml ]; then echo --coverage-clover build/logs/clover.xml; fi )
fi

# Run YUI Compressor Check
if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && [ 0 != $( cat /tmp/checked-files | grep '.js' | wc -l ) ]; then
	YUI_COMPRESSOR_PATH=/tmp/yuicompressor-2.4.8.jar
	wget -O "$YUI_COMPRESSOR_PATH" https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar
	cat /tmp/checked-files | grep '.js' | xargs --no-run-if-empty java -jar "$YUI_COMPRESSOR_PATH" -o /dev/null 2>&1
fi
