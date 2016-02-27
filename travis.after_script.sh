#!/bin/bash

set -e
set -v

function is_supported {
	php -r 'exit( version_compare( PHP_VERSION, "5.5.0", ">=" ) ? 0 : 1 );'
}
if is_supported && [ -s "$TEMP_DIRECTORY/paths-scope-php" ] && [ -e .coveralls.yml ]; then
	php vendor/bin/coveralls;
fi
