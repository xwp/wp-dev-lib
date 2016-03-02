#!/bin/bash

set -e
set -v

if can_generate_coverage_clover && [ -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
	echo -n "Current directory: "
	pwd
	mkdir -p build/logs
	php vendor/bin/coveralls -vvv
fi
