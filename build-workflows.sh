#!/bin/bash

set -e

rm -rf ./workflows/dist
./node_modules/.bin/babel ./workflows/src --out-dir ./workflows/dist
mv ./workflows/dist/gulpfile.babel.js ./workflows/dist/gulpfile.js
