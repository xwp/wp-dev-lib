#!/bin/bash

set -e
set -v

if [ -e .coveralls.yml ]; then php vendor/bin/coveralls --root_dir "$PROJECT_DIR"; fi
