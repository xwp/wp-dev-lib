#!/bin/bash

set -e
shopt -s expand_aliases

# TODO: We know that $DEV_LIB_PATH is _this_ directory, use that directly.
source "$DEV_LIB_PATH/check-diff.sh"

set_environment_variables
install_tools
