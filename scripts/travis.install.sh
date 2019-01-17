#!/bin/bash

set -e
shopt -s expand_aliases

# TODO: We know that $DEV_LIB_PATH is _this_ directory, use that directly.
source "$DEV_LIB_PATH/check-diff.sh"

# The following should be temporary. See <https://core.trac.wordpress.org/ticket/40086>, <https://core.trac.wordpress.org/ticket/39822>.
if check_should_execute 'phpunit'; then
  if [[ -z "$PHPUNIT_VERSION" ]]; then
    if [[ ${TRAVIS_PHP_VERSION:0:2} == "7." ]]; then
      PHPUNIT_VERSION='5.7'
    elif [[ ${TRAVIS_PHP_VERSION:0:3} != "5.2" ]]; then
      PHPUNIT_VERSION='4.8'
    fi
  fi
  if [[ ! -z "$PHPUNIT_VERSION" ]]; then
    mkdir -p $HOME/phpunit-bin/$PHPUNIT_VERSION
    echo "Opting for phpunit $PHPUNIT_VERSION for PHP $TRAVIS_PHP_VERSION"
    export PATH="$HOME/phpunit-bin/$PHPUNIT_VERSION:$PATH"
    if [[ ! -e $HOME/phpunit-bin/$PHPUNIT_VERSION/phpunit ]]; then
      wget -O $HOME/phpunit-bin/$PHPUNIT_VERSION/phpunit https://phar.phpunit.de/phpunit-$PHPUNIT_VERSION.phar
      chmod +x $HOME/phpunit-bin/$PHPUNIT_VERSION/phpunit
    fi
  fi
fi

set_environment_variables
install_tools
