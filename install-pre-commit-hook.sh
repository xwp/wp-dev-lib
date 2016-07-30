#!/bin/bash
# Link pre-commit hook for a repo in the directory supplied as an argument, or the parent repo of this file.
#
# USAGES:
# $ /path/to/install-pre-commit-hook.sh
# $ /path/to/install-pre-commit-hook.sh wp-content/themes/my-theme

set -e

# Store the initial directory to return back to it later
OLDPWD=`pwd`

# Navigate to the script directory
cd `dirname $0`

# Get full path of the script directory
BINDIR=`pwd`

# Get back to the calling directory
cd - &> /dev/null

# If passed a destination, switch to it to get the full path and then .git/hooks directory
if [ ! -z $1 ]; then
	cd $1
	DEST=`pwd`
fi

# Get the hooks directory of the current git repo
cd `git rev-parse --git-dir`/hooks

# Get relative path to the original file from within the hooks directory
RELPATH=`perl -e 'use File::Spec; print File::Spec->abs2rel(@ARGV) . "\n"' $BINDIR/pre-commit $(pwd)`

echo "## Placing pre-commit file in `pwd` from $RELPATH"
ln -s $RELPATH .

# Return back to the calling directory
cd $OLDPWD &> /dev/null
