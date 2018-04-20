#!/bin/bash

set -e
set -v

if can_generate_coverage_clover && [ -s "$TEMP_DIRECTORY/paths-scope-php" ] && [ -n "$INITIAL_DIR" ]; then
	cd "$INITIAL_DIR"
	php vendor/bin/coveralls -vvv
	cd - > /dev/null
fi
