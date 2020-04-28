#!/bin/bash

set -e

echo "## Checking files, scope $CHECK_SCOPE:"
if [[ -z $SKIP_ECHO_PATHS_SCOPE ]] && [[ $CHECK_SCOPE != "all" ]]; then
	cat "$TEMP_DIRECTORY/paths-scope"
fi
echo

# Run any custom tests by defining a run_tests function, see sample-scripts/.dev-lib
if [ "$( type -t run_tests )" != '' ]; then
	run_tests
fi

check_execute_bit
lint_js_files
lint_php_files
lint_xml_files
run_qunit
run_phpunit_travisci
run_codeception

# Run any custom tests after all other tests by defining a run_after_tests function, see sample-scripts/.dev-lib
if [ "$( type -t run_after_tests )" != '' ]; then
	run_after_tests
fi
