#!/bin/bash

set -e

# Run PHP syntax check
find $PATH_INCLUDES -path ./bin -prune -o \( -name '*.php' \) -exec php -lf {} \;

# Run JSHint
jshint $( if [ -e .jshintignore ]; then echo "--exclude-path .jshintignore"; fi ) $(find $PATH_INCLUDES -name '*.js')

# Run JSCS
jscs --verbose --config="$JSCS_CONFIG"  $(find $PATH_INCLUDES -name '*.js')

# Run PHP_CodeSniffer
$PHPCS_DIR/scripts/phpcs --standard=$WPCS_STANDARD $(if [ -n "$PHPCS_IGNORE" ]; then echo --ignore=$PHPCS_IGNORE; fi) $(find $PATH_INCLUDES -name '*.php')

# Run PHPUnit tests
if [ -e phpunit.xml ] || [ -e phpunit.xml.dist ]; then
	phpunit $( if [ -e .coveralls.yml ]; then echo --coverage-clover build/logs/clover.xml; fi )
fi

# Run YUI Compressor Check
if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && 0 != $( find $PATH_INCLUDES -name '*.js' | wc -l ); then
	YUI_COMPRESSOR_PATH=/tmp/yuicompressor-2.4.8.jar
	wget -O "$YUI_COMPRESSOR_PATH" https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar
	java -jar "$YUI_COMPRESSOR_PATH" -o /dev/null $( find $PATH_INCLUDES -name '*.js' ) 2>&1
fi
