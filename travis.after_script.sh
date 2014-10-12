#!/bin/bash

set -e

if [ -e .coveralls.yml ]; then php vendor/bin/coveralls; fi
