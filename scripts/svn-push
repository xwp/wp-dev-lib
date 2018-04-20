#!/bin/bash
# Given a svn-url file one directory up, export the latest git commits to the specified SVN repo.
# Create a git release tag from the version specified in the plugin file.
# Author: Weston Ruter (@westonruter)

set -e

cd "$( dirname $0 )"
dev_lib_dir=$(pwd)
cd ..


if [ -e .dev-lib ]; then
	source .dev-lib
elif [ -e .ci-env.sh ]; then
	source .ci-env.sh
fi
if [ -e svn-url ]; then
	SVN_URL=$(cat svn-url)
fi

if [ -z "$SVN_URL" ]; then
	echo "Error: Missing SVN_URL" >&2
	exit 1
fi

force=
while getopts 'f' option; do
	case $option in
		f)
			force=1
			;;
	esac
done

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ $current_branch != 'master' ]; then
	echo "Please checkout the master branch"
	exit 1
fi

if [ -n "$(git status -s -uno)" ] && [ -z "$force" ]; then
	git status
	echo "Error: Git state has modified or staged files. Commit or reset, or supply -f" >&2
	exit 1
fi

git_root=$(pwd)

if [ -e readme.txt ]; then
	$dev_lib_dir/generate-markdown-readme
	git add readme.md
fi
if [ -n "$(git status --porcelain readme.md)" ]; then
	echo "Please commit (--amend?) the updated readme.md"
	exit 1
fi

git pull --ff-only origin master
git push origin master
git_root_hash=$(md5sum <<< "$git_root" | cut -c1-32)
plugin_uniq_slug="$(basename "$git_root")-$git_root_hash"
lock_file="/tmp/$plugin_uniq_slug.lock"
svn_tmp_repo_dir="/tmp/svn-$plugin_uniq_slug"
git_tmp_repo_dir="/tmp/git-$plugin_uniq_slug"
echo "Temp SVN dir: $svn_tmp_repo_dir"
echo "Temp Git dir: $git_tmp_repo_dir"

for php in *.php; do
	if grep -q 'Plugin Name:' $php && grep -q 'Version:' $php; then
		plugin_version=$(cat $php | grep 'Version:' | sed 's/.*Version: *//')
	fi
done

if [ -z "$plugin_version" ]; then
	echo "Unable to find plugin version"
	exit 1
fi

if ! grep -q "$plugin_version" readme.txt; then
	echo "Please update readme.txt to include $plugin_version in changelog"
	exit 1
fi

if git show-ref --tags --quiet --verify -- "refs/tags/$plugin_version"; then
	has_tag=1
fi

if [ -n "$has_tag" ] && [ -z "$force" ]; then
	echo "Plugin version $plugin_version already tagged. Please bump version and try again, or supply -f"
	exit 1
fi

# Clean up existing Git and SVN repos
if [ -e "$lock_file" ] || ( [ -e "$svn_tmp_repo_dir" ] && [ ! -e "$svn_tmp_repo_dir/.svn" ] ); then
	echo "Cleanup $svn_tmp_repo_dir"
	rm -rf "$svn_tmp_repo_dir"
fi
if [ -e "$lock_file" ] || ( [ -e "$git_tmp_repo_dir" ] && [ ! -e "$git_tmp_repo_dir/.git" ] ); then
	echo "Cleanup $git_tmp_repo_dir"
	rm -rf "$git_tmp_repo_dir"
fi

touch "$lock_file"

# SVN: Checkout or update
if [ ! -e $svn_tmp_repo_dir ]; then
	svn checkout $SVN_URL $svn_tmp_repo_dir
	cd $svn_tmp_repo_dir
else
	cd $svn_tmp_repo_dir
	svn up
fi

# Git: Clone or pull
if [ ! -e $git_tmp_repo_dir ]; then
	git clone $git_root $git_tmp_repo_dir
	cd $git_tmp_repo_dir
else
	cd $git_tmp_repo_dir
	git pull
fi

# rsync all committed files from the Git repo to SVN
rsync -avz --delete --delete-excluded \
	--exclude '/.david-dev' \
	--exclude '/package.json' \
	--exclude '/contributing.md' \
	--exclude '/composer.json' \
	--exclude '/Gruntfile.js' \
	--exclude '/readme.md' \
	--exclude '/.ci-env.sh' \
	--exclude '/.dev-lib' \
	--exclude '/.coveralls.yml' \
	--exclude '/.git*' \
	--exclude '/.jscsrc' \
	--exclude '/.eslintrc' \
	--exclude '/.jshint*' \
	--exclude '/.mailmap' \
	--exclude '/.travis.yml' \
	--exclude '/assets' \
	--exclude '/dev-lib' \
	--exclude '/svn-url' \
	--exclude '/tests' \
	--exclude 'phpunit.xml*' \
	--exclude 'phpcs.ruleset.xml' \
	$git_tmp_repo_dir/ $svn_tmp_repo_dir/trunk/
if [ -e $git_tmp_repo_dir/assets/ ]; then
	mkdir -p $svn_tmp_repo_dir/assets/
	rsync -avz --delete --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.svg' --exclude='*' --delete-excluded $git_tmp_repo_dir/assets/ $svn_tmp_repo_dir/assets/
fi
cd $svn_tmp_repo_dir

if svn status | grep -s '^!'; then
	svn status | grep '^!' | awk '{print $2}' | xargs svn delete --force
fi
svn add --force trunk/ --auto-props --parents --depth infinity -q
if [ -e assets/ ]; then
	svn add --force assets/ --auto-props --parents --depth infinity -q
fi

mkdir -p tags
if [ -e tags/$plugin_version ]; then
	svn rm --force tags/$plugin_version
fi
mkdir -p tags/$plugin_version
rsync -avz trunk/ tags/$plugin_version/
svn add --force tags/$plugin_version --auto-props --parents --depth infinity -q

# Add mime types
while read extension mime_type; do
	if [[ "$extension" = \#* ]] || [ -z "$extension" ] || [ -z "$mime_type" ]; then
		continue
	fi
	echo "Set mime-type $mime_type on all $extension files..."

	OLD_IFS="$IFS"
	IFS=$'\n'
	for file in $( find . -name "*.$extension" ); do
		if svn info "$file" 1>/dev/null 2>&1; then
			svn propset svn:mime-type "$mime_type" "$file"
		fi
	done
	IFS="$OLD_IFS"
done < "$dev_lib_dir/mime-types.csv"

svn_commit_file=/tmp/svn-commit-msg
git --git-dir $git_root/.git log -1 --format="Update to commit %h from $(git --git-dir $git_root/.git config --get remote.origin.url)" > $svn_commit_file

svn status
echo
echo "SVN Commit message:"
cat $svn_commit_file
echo

echo "Hit enter to proceed with SVN commit and Git tag"
read OK

if [ -z "$has_tag" ]; then
	cd "$git_root"
	echo "Tagging plugin version $plugin_version"
	git tag "$plugin_version" master
	git push origin "$plugin_version"
else
	echo "Skipping plugin tag $plugin_version since already exists"
fi

cd $svn_tmp_repo_dir
svn commit -F $svn_commit_file
rm "$lock_file"
