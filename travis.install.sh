#!/bin/bash

set -e
shopt -s expand_aliases
source "$DEV_LIB_PATH/check-diff.sh"
set_environment_variables
install_tools
