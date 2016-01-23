#!/bin/bash
# Install pre-commit hook on all plugin and theme repos and upgrade wp-dev-lib submodules
# for all subdirectories under the current working directory.
# By default the shared wp-dev-lib repo gets cloned into ~/Projects/wp-dev-lib but
# this can be overridden by supplying the path as the first argument.
# Author: Weston Ruter, XWP
# URL: https://github.com/xwp/wp-dev-lib

set -e

repo_url=https://github.com/xwp/wp-dev-lib.git
shared_dev_lib_dir="$HOME/Projects/wp-dev-lib"
if [ ! -z "$1" ]; then
	shared_dev_lib_dir="$1"
fi
mkdir -p "$shared_dev_lib_dir"

if [ ! -e "$shared_dev_lib_dir/.git" ]; then
	echo "Cloning shared wp-dev-lib into $shared_dev_lib_dir"
	git clone "$repo_url" "$shared_dev_lib_dir"
else
	echo "Updating shared wp-dev-lib in $shared_dev_lib_dir"
	cd "$shared_dev_lib_dir"
	git pull "$repo_url" master
	cd - > /dev/null
fi

echo "Gathering list of plugins and themes under $PWD"
echo
for plugin_git_dir in $( find . -type d \( -path '*/wp-content/plugins/*/.git' -o -path '*/wp-content/themes/*/.git' \) ); do
	if [ -d "$plugin_git_dir/hooks" ] && [ ! -e "$plugin_git_dir/hooks/pre-commit" ]; then
		echo "## Installing pre-commit hook to $plugin_git_dir"
		ln -sf "$shared_dev_lib_dir/pre-commit" "$plugin_git_dir/hooks/pre-commit"
		echo
	fi
done

echo "Checking out latest version of dev-lib for all submodules"
echo
for dev_lib_dir in $( find . -name 'dev-lib' -type d \! -path '*/.git/*' ); do
	echo "## Updating dev-lib in $dev_lib_dir"
	cd "$dev_lib_dir";
	git checkout master;
	if ! git pull --ff-only "$shared_dev_lib_dir" master; then
	echo "Could not update submodule"
	git status
	fi
	cd - > /dev/null
	echo
done
