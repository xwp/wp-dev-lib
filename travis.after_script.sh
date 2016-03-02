#!/bin/bash

set -e
set -v

if can_generate_coverage_clover && [ -s "$TEMP_DIRECTORY/paths-scope-php" ] && [ -n "$PHPUNIT_COVERAGE_DIR" ]; then
	cd "$PHPUNIT_COVERAGE_DIR"
	php vendor/bin/coveralls -vvv
	cd - > /dev/null
fi
