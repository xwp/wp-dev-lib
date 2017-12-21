#!/bin/bash

set -e
set -v

if can_generate_coverage_clover && [ -s "$TEMP_DIRECTORY/paths-scope-php" ] && [ -n "$INITIAL_DIR" ]; then
	cd "$INITIAL_DIR"

	# Coveralls 1.x.x path
	COVERALLS_BIN="vendor/bin/coveralls";

	# Coveralls 2.x.x path
	if [ ! -e "$COVERALLS_BIN" ]; then
		COVERALLS_BIN="vendor/bin/php-coveralls"
	fi

	if [ -e "$COVERALLS_BIN" ]; then
	    php $COVERALLS_BIN -vvv
	fi

	cd - > /dev/null
fi
