#!/bin/bash

if [ -e .coveralls.yml ]; then php vendor/bin/coveralls; fi
