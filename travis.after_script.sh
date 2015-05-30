#!/bin/bash

set -e
set -v

if [ -e .coveralls.yml ]; then php -d extension=phar.so composer.phar [vendor/bin/coveralls]; fi
