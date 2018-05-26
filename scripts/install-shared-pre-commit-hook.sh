#!/bin/bash
# Install pre-commit hook on all plugin and theme repos and upgrade wp-dev-lib submodules
# for all subdirectories under the current working directory, or for the directory supplied
# as an argument.
#
# USAGES:
# $ cd ~/root/project/dir ~/Shared/wp-dev-lib/install-upgrade-pre-commit-hook.sh
# $ ./install-upgrade-pre-commit-hook.sh ~/root/project/dir

set -e

cd "$(dirname "$0")"
dev_lib_dir="$(pwd)"
cd - > /dev/null

if [ ! -z "$1" ]; then
	cd "$1"
	working_directory="$(pwd)"
	cd - > /dev/null
else
	working_directory="$(pwd)"
fi

echo "Root directory: $working_directory"

repo_url=https://github.com/xwp/wp-dev-lib.git
shared_dev_lib_dir="$HOME/Projects/wp-dev-lib"
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
for repo_git_dir in $( find "$working_directory" -type d \( -path '*/wp-content/plugins/*/.git' -o -path '*/wp-content/themes/*/.git' \) ); do
	if [ -d "$repo_git_dir/hooks" ] && [ ! -e "$repo_git_dir/hooks/pre-commit" ]; then
		repo_dir="$(dirname "$repo_git_dir")"
		echo "## Installing pre-commit hook to $repo_dir"
		if [ -e "$repo_dir/dev-lib/pre-commit" ]; then
			ln -sf "../../dev-lib/pre-commit" "$repo_git_dir/hooks/pre-commit"
		else
			ln -sf "$shared_dev_lib_dir/pre-commit" "$repo_git_dir/hooks/pre-commit"
		fi
		echo
	fi
done

echo "Checking out latest version of dev-lib for all submodules"
echo
for dev_lib_dir in $( find "$working_directory" -name 'dev-lib' -type d \! -path '*/.git/*' ); do
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
