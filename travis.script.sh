#!/bin/bash

set -e

echo "## Checking files, scope $CHECK_SCOPE:"
cat "$TEMP_DIRECTORY/paths-scope"
echo

check_execute_bit
check_js_files
check_php_files
run_phpunit_travisci
run_codeception
