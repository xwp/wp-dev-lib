#!/bin/bash

set -e
set -v

if min_php_version "5.5.0" && ! grep -sqi 'phpunit' <<< "$DEV_LIB_SKIP" && [ -s "$TEMP_DIRECTORY/paths-scope-php" ] && [ -e .coveralls.yml ]; then
	php vendor/bin/coveralls;
fi
