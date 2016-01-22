#!/bin/bash

set -e
set -v

if [ -s "$TEMP_DIRECTORY/paths-scope-php" ] && [ -e .coveralls.yml ]; then php vendor/bin/coveralls; fi
