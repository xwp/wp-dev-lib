#!/bin/bash

set -e

function realpath {
	php -r 'echo realpath( $argv[1] );' "$1"
}

function min_php_version () {
	php -r 'if ( version_compare( phpversion(), $argv[1], "<" ) ) { exit( 1 ); }' "$1"
}

function upsearch {
	# via http://unix.stackexchange.com/a/13474
	slashes=${PWD//[^\/]/}
	directory="./"
	for (( n=${#slashes}; n>0; --n )); do
		test -e "$directory/$1" && echo "$directory/$1" && return
		if [ "$2" != 'git_boundless' ] && test -e '.git'; then
			return
		fi
		directory="$directory/.."
	done
}

function remove_diff_range {
	sed 's/:[0-9][0-9]*-[0-9][0-9]*$//' | sort | uniq
}

function set_environment_variables {

	TEMP_DIRECTORY=$(mktemp -d 2>/dev/null || mktemp -d -t 'dev-lib')
	PROJECT_DIR=$( git rev-parse --show-toplevel )
	DEV_LIB_PATH=${DEV_LIB_PATH:-$( dirname "$0" )/}
	DEV_LIB_PATH=$(realpath "$DEV_LIB_PATH")
	PROJECT_SLUG=${PROJECT_SLUG:-$( basename "$PROJECT_DIR" | sed 's/^wp-//' )}
	PATH_INCLUDES=${PATH_INCLUDES:-./}
	PATH_EXCLUDES_PATTERN=${PATH_EXCLUDES_PATTERN:-'^(.*/)?(vendor|bower_components|node_modules)/.*'}

	if [ -z "$PROJECT_TYPE" ]; then
		if [ -e style.css ]; then
			PROJECT_TYPE=theme
		elif grep -isqE "^[     ]*\*[     ]*Plugin Name[     ]*:" "$PROJECT_DIR"/*.php; then
			PROJECT_TYPE=plugin
		elif [ $( find . -maxdepth 2 -name wp-config.php | wc -l | sed 's/ //g' ) -gt 0 ]; then
			PROJECT_TYPE=site
		else
			PROJECT_TYPE=unknown
		fi
	fi

	if [ ! -z "$LIMIT_TRAVIS_PR_CHECK_SCOPE" ]; then
		echo "LIMIT_TRAVIS_PR_CHECK_SCOPE is obsolete; use CHECK_SCOPE env var instead" 1>&2
		return 1
	fi
	CHECK_SCOPE=${CHECK_SCOPE:-patches} # 'all', 'changed-files', 'patches'

	if [ "$TRAVIS" == true ]; then
		if [[ "$TRAVIS_PULL_REQUEST" != 'false' ]]; then

			# Make sure the remote branch is fetched.
			if [[ -z "$DIFF_BASE" ]] && ! git rev-parse --verify --quiet "$TRAVIS_BRANCH"; then
				git fetch origin "$TRAVIS_BRANCH"
				git branch "$TRAVIS_BRANCH" FETCH_HEAD
			fi

			DIFF_BASE=${DIFF_BASE:-$TRAVIS_BRANCH}
		else
			DIFF_BASE=${DIFF_BASE:-$TRAVIS_COMMIT^}
		fi
		DIFF_HEAD=${DIFF_HEAD:-$TRAVIS_COMMIT}
	else
		DIFF_BASE=${DIFF_BASE:-HEAD}
		DIFF_HEAD=${DIFF_HEAD:-WORKING}
	fi
	while [[ $# > 0 ]]; do
		key="$1"
		case "$key" in
			-b|--diff-base)
				DIFF_BASE="$2"
				shift # past argument
			;;
			-h|--diff-head)
				DIFF_HEAD="$2"
				shift # past argument
			;;
			-s|--scope)
				CHECK_SCOPE="$2"
				shift # past argument
			;;
			-i|--ignore-paths)
				IGNORE_PATHS="$2"
				shift # past argument
			;;
			-v|--verbose)
				VERBOSE=1
			;;
			*)
				# unknown option
			;;
		esac
		shift # past argument or value
	done

	# TODO: Change back to https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar once 3.x compat is done.
	PHPCS_PHAR_URL=https://github.com/squizlabs/PHP_CodeSniffer/releases/download/2.9.0/phpcs.phar
	if [ -z "$PHPCS_RULESET_FILE" ]; then
		for SEARCHED_PHPCS_RULESET_FILE in phpcs.xml phpcs.xml.dist phpcs.xml phpcs.ruleset.xml; do
			PHPCS_RULESET_FILE="$( upsearch $SEARCHED_PHPCS_RULESET_FILE)"
			if [ ! -z "$PHPCS_RULESET_FILE" ]; then
				break
			fi
		done
	fi
	PHPCS_IGNORE=${PHPCS_IGNORE:-'vendor/*'}
	PHPCS_GIT_TREE=${PHPCS_GIT_TREE:-master}
	PHPCS_GITHUB_SRC=${PHPCS_GITHUB_SRC:-squizlabs/PHP_CodeSniffer}

	WPCS_DIR=${WPCS_DIR:-/tmp/wpcs}
	WPCS_GITHUB_SRC=${WPCS_GITHUB_SRC:-WordPress-Coding-Standards/WordPress-Coding-Standards}
	WPCS_GIT_TREE=${WPCS_GIT_TREE:-master}
	WPCS_STANDARD=${WPCS_STANDARD:-WordPress-Core}

	if [ -z "$CODECEPTION_CONFIG" ] && [ -e codeception.yml ]; then
		CODECEPTION_CONFIG=codeception.yml
	fi

	DB_HOST=${DB_HOST:-localhost}
	DB_NAME=${DB_NAME:-wordpress_test}
	DB_USER=${DB_USER:-root}
	DB_PASS=${DB_PASS:-root}

	if [ -z "$WP_INSTALL_TESTS" ]; then
		if [ "$TRAVIS" == true ]; then
			WP_INSTALL_TESTS=true
		else
			WP_INSTALL_TESTS=false
		fi
	fi
	WP_CORE_DIR=${WP_CORE_DIR:-/tmp/wordpress}
	WP_VERSION=${WP_VERSION:-latest}

	YUI_COMPRESSOR_CHECK=${YUI_COMPRESSOR_CHECK:-1}
	YUI_COMPRESSOR_PATH=/tmp/yuicompressor-2.4.8.jar
	DISALLOW_EXECUTE_BIT=${DISALLOW_EXECUTE_BIT:-0}
	SYNC_README_MD=${SYNC_README_MD:-1}

	VERBOSE=${VERBOSE:-0}
	CODECEPTION_CHECK=${CODECEPTION_CHECK:-1}
	VAGRANTFILE=$( upsearch 'Vagrantfile' git_boundless )

	if [ -z "$JSCS_CONFIG" ]; then
		JSCS_CONFIG="$( upsearch .jscsrc )"
	fi
	if [ -z "$JSCS_CONFIG" ]; then
		JSCS_CONFIG="$( upsearch .jscs.json )"
	fi

	if [ -z "$JSHINT_CONFIG" ]; then
		JSHINT_CONFIG="$( upsearch .jshintrc )"
	fi
	if [ -z "$JSHINT_CONFIG" ]; then
		JSHINT_CONFIG="$DEV_LIB_PATH/.jshintrc"
	fi
	if [ -z "$JSHINT_IGNORE" ]; then
		JSHINT_IGNORE="$( upsearch .jshintignore )"
	fi

	if [ -z "$ESLINT_CONFIG" ]; then
		ESLINT_CONFIG="$( upsearch .eslintrc )"
	fi
	if [ -z "$ESLINT_IGNORE" ]; then
		ESLINT_IGNORE="$( upsearch .eslintignore )"
	fi

	# Load any environment variable overrides from config files
	ENV_FILE=$( upsearch .ci-env.sh )
	if [ ! -z "$ENV_FILE" ]; then
		source "$ENV_FILE"
	fi
	ENV_FILE=$( upsearch .dev-lib )
	if [ ! -z "$ENV_FILE" ]; then
		source "$ENV_FILE"
	fi

	if [ ! -e "$PROJECT_DIR/.git" ]; then
		echo "Error: Must run from Git root" 1>&2
		return 1
	fi

	CHECK_SCOPE=$( tr '[A-Z]' '[a-z]' <<< "$CHECK_SCOPE" )
	if [ "$CHECK_SCOPE" == 'files' ]; then
		CHECK_SCOPE='changed-files'
	fi

	if [ "$CHECK_SCOPE" != 'all' ] && [ "$CHECK_SCOPE" != 'changed-files' ] && [ "$CHECK_SCOPE" != 'patches' ]; then
		echo "Error: CHECK_SCOPE must be 'all', 'changed-files', or 'patches'" 1>&2
		return 1
	fi

	if [ "$DIFF_HEAD" == 'INDEX' ]; then
		DIFF_HEAD='STAGE'
	fi

	if [ "$DIFF_BASE" == 'HEAD' ] && [ "$DIFF_HEAD" != 'STAGE' ] && [ "$DIFF_HEAD" != 'WORKING' ]; then
		echo "Error: when DIFF_BASE is 'HEAD' then DIFF_HEAD must be 'STAGE' or 'WORKING' (you supplied '$DIFF_HEAD')" 1>&2
		return 1
	fi
	if [ "$DIFF_HEAD" == 'WORKING' ] && [ "$DIFF_BASE" != 'STAGE' ] && [ "$DIFF_BASE" != 'HEAD' ]; then
		echo "Error: when DIFF_HEAD is 'WORKING' then DIFF_BASE must be 'STAGE' or 'HEAD' (you supplied '$DIFF_BASE')" 1>&2
		return 1
	fi
	if [ "$TRAVIS" == 'true' ]; then
		if [ "$DIFF_HEAD" == 'WORKING' ]; then
			echo "Error: DIFF_HEAD cannot be WORKING in TRAVIS" 1>&2
			return 1
		fi
		if [ "$DIFF_HEAD" == 'STAGE' ]; then
			echo "Error: DIFF_HEAD cannot be STAGE in TRAVIS" 1>&2
			return 1
		fi
	fi

	# treeishA to treeishB (git diff treeishA...treeishB)
	# treeish to STAGE (git diff --staged treeish)
	# HEAD to WORKING [default] (git diff HEAD)
	if [ "$DIFF_HEAD" == 'STAGE' ]; then
		if [ "$DIFF_BASE" == 'HEAD' ]; then
			DIFF_ARGS="--staged"
		else
			DIFF_ARGS="$DIFF_BASE --staged"
		fi
	elif [ "$DIFF_HEAD" == 'WORKING' ]; then
		DIFF_ARGS="$DIFF_BASE"
	else
		DIFF_ARGS="$DIFF_BASE...$DIFF_HEAD"
	fi

	echo "git diff $DIFF_ARGS"
	if [ "$CHECK_SCOPE" == 'patches' ]; then
		git diff --diff-filter=AM --no-prefix --unified=0 $DIFF_ARGS -- $PATH_INCLUDES | php "$DEV_LIB_PATH/diff-tools/parse-diff-ranges.php" > "$TEMP_DIRECTORY/paths-scope"
	elif [ "$CHECK_SCOPE" == 'changed-files' ]; then
		git diff --diff-filter=AM $DIFF_ARGS --name-only -- $PATH_INCLUDES > "$TEMP_DIRECTORY/paths-scope"
	else
		git ls-files -- $PATH_INCLUDES > "$TEMP_DIRECTORY/paths-scope"
	fi

	if [ ! -z "$PATH_EXCLUDES_PATTERN" ]; then
		cat "$TEMP_DIRECTORY/paths-scope" | grep -E -v "$PATH_EXCLUDES_PATTERN" | cat - > "$TEMP_DIRECTORY/excluded-paths-scope"
		mv "$TEMP_DIRECTORY/excluded-paths-scope" "$TEMP_DIRECTORY/paths-scope"
	fi

	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.php(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-php"
	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.jsx?(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-js"
	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.(css|scss)(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-scss"
	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.(xml|svg|xml.dist)(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-xml"

	# Gather the proper states of files to run through linting (this won't apply to phpunit)
	if [ "$DIFF_HEAD" != 'working' ]; then
		LINTING_DIRECTORY="$(realpath $TEMP_DIRECTORY)/index"
		mkdir -p "$LINTING_DIRECTORY"

		for path in $( cat "$TEMP_DIRECTORY/paths-scope" | remove_diff_range ); do
			# Skip submodules or files are deleted
			if [ -d "$path" ] ||  [ ! -e "$path" ]; then
				continue
			fi

			mkdir -p "$LINTING_DIRECTORY/$(dirname "$path")"
			if [ -L "$path" ]; then
				symlink_path=$(readlink "$path")
				mkdir -p "$LINTING_DIRECTORY/$(dirname "$symlink_path")"
				if git ls-files --error-unmatch -- "$symlink_path" > /dev/null 2>&1; then
					if [ "$DIFF_HEAD" == 'STAGE' ]; then
						git show :"$symlink_path" > "$LINTING_DIRECTORY/$symlink_path"
					else
						git show "$DIFF_HEAD":"$symlink_path" > "$LINTING_DIRECTORY/$symlink_path"
					fi
				else
					cp "$symlink_path" "$LINTING_DIRECTORY/$symlink_path"
				fi
				ln -s "$LINTING_DIRECTORY/$symlink_path" "$LINTING_DIRECTORY/$path"
			else
				if [ "$DIFF_HEAD" == 'STAGE' ]; then
					git show :"$path" > "$LINTING_DIRECTORY/$path"
				else
					git show "$DIFF_HEAD":"$path" > "$LINTING_DIRECTORY/$path"
				fi
			fi
		done

		# Make sure linter configs get copied linting directory since upsearch is relative.
		for linter_file in .jshintrc .jshintignore .jscsrc .jscs.json .eslintignore .eslintrc phpcs.xml phpcs.xml.dist phpcs.ruleset.xml ruleset.xml; do
			if git ls-files "$linter_file" --error-unmatch > /dev/null 2>&1; then
				if [ -L $linter_file ]; then
					ln -fs $(git show :"$linter_file") "$LINTING_DIRECTORY/$linter_file"
				else
					git show :"$linter_file" > "$LINTING_DIRECTORY/$linter_file";
				fi
			fi
		done
		if [ -e "$LINTING_DIRECTORY/$JSHINT_IGNORE" ]; then
			JSHINT_IGNORE="$( realpath "$LINTING_DIRECTORY/$JSHINT_IGNORE" )"
		fi

		# Make sure that all of the dev-lib is copied to the linting directory in case any configs extend instead of symlink.
		mkdir -p $LINTING_DIRECTORY/dev-lib
		rsync -avzq --exclude .git "$DEV_LIB_PATH/" "$LINTING_DIRECTORY/dev-lib/"

		# Use node_modules from actual directory (create node_modules symlink even if it won't be created).
		if [ -e "$PROJECT_DIR/package.json" ]; then
			if [ -e "$LINTING_DIRECTORY/node_modules" ]; then
				rm -r "$LINTING_DIRECTORY/node_modules"
			fi
			ln -s "$PROJECT_DIR/node_modules" "$LINTING_DIRECTORY/node_modules"
		fi
	else
		LINTING_DIRECTORY="$PROJECT_DIR"
	fi

	if [ -L "$JSHINT_IGNORE" ]; then
		echo "Warning: .jshintignore may not work as expected as symlink."
	fi

	if [ ! -z "$JSHINT_CONFIG" ]; then JSHINT_CONFIG=$(realpath "$JSHINT_CONFIG"); fi
	if [ ! -z "$JSHINT_IGNORE" ]; then JSHINT_IGNORE=$(realpath "$JSHINT_IGNORE"); fi
	if [ ! -z "$JSCS_CONFIG" ]; then JSCS_CONFIG=$(realpath "$JSCS_CONFIG"); fi
	if [ ! -z "$ENV_FILE" ]; then ENV_FILE=$(realpath "$ENV_FILE"); fi
	if [ ! -z "$PHPCS_RULESET_FILE" ]; then PHPCS_RULESET_FILE=$(realpath "$PHPCS_RULESET_FILE"); fi
	if [ ! -z "$CODECEPTION_CONFIG" ]; then CODECEPTION_CONFIG=$(realpath "$CODECEPTION_CONFIG"); fi
	if [ ! -z "$VAGRANTFILE" ]; then VAGRANTFILE=$(realpath "$VAGRANTFILE"); fi
	# Note: PHPUNIT_CONFIG must be a relative path for the sake of running in Vagrant

	return 0
}

function dump_environment_variables {
	echo 1>&2
	echo "## CONFIG VARIABLES" 1>&2

	# List obtained via ack -o '[A-Z][A-Z0-9_]*(?==)' | tr '\n' ' '
	for var in JSHINT_CONFIG LINTING_DIRECTORY TEMP_DIRECTORY DEV_LIB_PATH PROJECT_DIR PROJECT_SLUG PATH_INCLUDES PROJECT_TYPE CHECK_SCOPE DIFF_BASE DIFF_HEAD PHPCS_GITHUB_SRC PHPCS_GIT_TREE PHPCS_RULESET_FILE PHPCS_IGNORE WPCS_DIR WPCS_GITHUB_SRC WPCS_GIT_TREE WPCS_STANDARD WP_CORE_DIR WP_TESTS_DIR YUI_COMPRESSOR_CHECK DISALLOW_EXECUTE_BIT CODECEPTION_CHECK JSCS_CONFIG JSCS_CONFIG ENV_FILE ENV_FILE DIFF_BASE DIFF_HEAD CHECK_SCOPE IGNORE_PATHS HELP VERBOSE DB_HOST DB_NAME DB_USER DB_PASS WP_INSTALL_TESTS; do
		echo "$var=${!var}" 1>&2
	done
	echo 1>&2
}

function verbose_arg {
	if [ "$VERBOSE" == 1 ]; then
		echo '-v'
	fi
}

function download {
	if command -v curl >/dev/null 2>&1; then
		curl $(verbose_arg) -L -s "$1" > "$2"
	elif command -v wget >/dev/null 2>&1; then
		wget $(verbose_arg) -n -O "$2" "$1"
	else
		echo ''
		return 1
	fi
}

function can_generate_coverage_clover {
	if [ -e .coveralls.yml ] && [ -e composer.json ] && check_should_execute 'coverage'; then
		if min_php_version "5.5.0" && cat composer.json | grep -Eq '"satooshi/php-coveralls"\s*:\s*"dev-master"'; then
			return 0
		elif min_php_version "5.3.0" && cat composer.json | grep -Eq '"satooshi/php-coveralls"\s*:\s*"~1.0"'; then
			return 0
		fi
	fi
	return 1
}

function coverage_clover {
	if can_generate_coverage_clover; then
		echo --coverage-clover build/logs/clover.xml
	fi
}

function install_tools {
	TEMP_TOOL_PATH="/tmp/dev-lib-bin"
	mkdir -p "$TEMP_TOOL_PATH"
	PATH="$TEMP_TOOL_PATH:$PATH"

	if ! min_php_version "5.3.0" && check_should_execute 'composer'; then
		pecl install phar
		DEV_LIB_SKIP="$DEV_LIB_SKIP,composer"
	fi

	# Skip installing Composer when the PHP version does not meet the php-coveralls package requirements.
	if ! min_php_version "5.5.0" && [ -e composer.json ] && check_should_execute 'composer' && cat composer.json | grep -Eq '"satooshi/php-coveralls"\s*:\s*"dev-master"'; then
		DEV_LIB_SKIP="$DEV_LIB_SKIP,composer"
	fi

	# Install Node packages.
	if [ -e package.json ] && [ $( ls node_modules | wc -l ) == 0 ]; then
		npm install
	fi

	# Install PHP tools.
	if [ -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
		if [ -z "$( type -t phpunit )" ] && check_should_execute 'phpunit'; then
			PHPUNIT_VERSION=${PHPUNIT_VERSION:-5.7}
			echo "Downloading PHPUnit $PHPUNIT_VERSION phar"
			download https://phar.phpunit.de/phpunit-$PHPUNIT_VERSION.phar "$TEMP_TOOL_PATH/phpunit"
			chmod +x "$TEMP_TOOL_PATH/phpunit"
		fi

		if ! check_should_execute 'phpcs'; then
			echo "Skipping PHPCS per DEV_LIB_SKIP / DEV_LIB_ONLY"
		elif [ -z "$WPCS_STANDARD" ]; then
			echo "Skipping PHPCS since WPCS_STANDARD (and PHPCS_RULESET_FILE) is empty." 1>&2
		else
			if [ "$( type -t phpcs )" == '' ]; then
				echo "Downloading PHPCS phar"
				download "$PHPCS_PHAR_URL" "$TEMP_TOOL_PATH/phpcs"
				chmod +x "$TEMP_TOOL_PATH/phpcs"
			fi

			if ! phpcs -i | grep -q 'WordPress'; then
				if [ ! -e "$WPCS_DIR" ]; then
					GIT_WORK_TREE_RESTORE="$GIT_WORK_TREE"
					unset GIT_WORK_TREE
					git clone -b "$WPCS_GIT_TREE" "https://github.com/$WPCS_GITHUB_SRC.git" $WPCS_DIR
					GIT_WORK_TREE="$GIT_WORK_TREE_RESTORE"
				fi
				phpcs --config-set installed_paths $WPCS_DIR
			fi
		fi
	fi

	# Install JS tools.
	if [ -s "$TEMP_DIRECTORY/paths-scope-js" ]; then

		# Install Grunt
		if check_should_execute 'grunt' && [ "$( type -t grunt )" == '' ] && [ ! -e "$(npm bin)/grunt" ]; then
			echo "Installing Grunt"
			if ! npm install -g grunt-cli 2>/dev/null; then
				echo "Failed to install grunt-cli (try manually doing: sudo npm install -g grunt-cli), so skipping grunt-cli"
				DEV_LIB_SKIP="$DEV_LIB_SKIP,grunt"
			fi
		fi

		# Install JSHint
		if [ "$( type -t jshint )" == '' ] && check_should_execute 'jshint'; then
			echo "Installing JSHint"
			if ! npm install -g jshint 2>/dev/null; then
				echo "Failed to install jshint (try manually doing: sudo npm install -g jshint), so skipping jshint"
				DEV_LIB_SKIP="$DEV_LIB_SKIP,jshint"
			fi
		fi

		# Install jscs
		if [ -n "$JSCS_CONFIG" ] && [ -e "$JSCS_CONFIG" ] && [ "$( type -t jscs )" == '' ] && check_should_execute 'jscs'; then
			echo "JSCS"
			if ! npm install -g jscs 2>/dev/null; then
				echo "Failed to install jscs (try manually doing: sudo npm install -g jscs), so skipping jscs"
				DEV_LIB_SKIP="$DEV_LIB_SKIP,jscs"
			fi
		fi

		# Install ESLint
		if [ -n "$ESLINT_CONFIG" ] && [ -e "$ESLINT_CONFIG" ] && [ ! -e "$(npm bin)/eslint" ] && check_should_execute 'eslint'; then
			echo "Installing ESLint"
			if ! npm install -g eslint 2>/dev/null; then
				echo "Failed to install eslint (try manually doing: sudo npm install -g eslint), so skipping eslint"
				DEV_LIB_SKIP="$DEV_LIB_SKIP,eslint"
			fi
		fi

		# YUI Compressor
		if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && command -v java >/dev/null 2>&1 && check_should_execute 'yuicompressor'; then
			if [ ! -e "$YUI_COMPRESSOR_PATH" ]; then
				download https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar "$YUI_COMPRESSOR_PATH"
			fi
		fi
	fi

	# Install Composer
	if [ -e composer.json ] && check_should_execute 'composer' && [ $( ls vendor | wc -l ) == 0 ]; then
		if [ "$( type -t composer )" == '' ]; then
			(
				cd "$TEMP_TOOL_PATH"
				download "http://getcomposer.org/installer" composer-installer.php
				php composer-installer.php
				mv composer.phar composer
				chmod +x composer
			)
		fi

		composer install
	fi
}

## Begin functions for phpunit ###########################

function install_wp {

	if [ -d "$WP_CORE_DIR" ]; then
		return 0
	fi
	if [ "$( type -t svn )" == '' ]; then
		echo "install_wp failure: svn is not installed"
		return 1
	fi

	if grep -isqE 'trunk|alpha|beta|rc' <<< "$WP_VERSION"; then
		local SVN_URL=https://develop.svn.wordpress.org/trunk/
	elif [ "$WP_VERSION" == 'latest' ]; then
		local TAG=$( svn ls https://develop.svn.wordpress.org/tags | tail -n 1 | sed 's:/$::' )
		local SVN_URL="https://develop.svn.wordpress.org/tags/$TAG/"
	else
		local SVN_URL="https://develop.svn.wordpress.org/tags/$WP_VERSION/"
	fi

	echo "Installing WP from $SVN_URL to $WP_CORE_DIR"

	svn export -q "$SVN_URL" "$WP_CORE_DIR"

	download https://raw.github.com/markoheijnen/wp-mysqli/master/db.php "$WP_CORE_DIR/src/wp-content/db.php"
}

function install_test_suite {
	# portable in-place argument for both GNU sed and Mac OSX sed
	if [[ $(uname -s) == 'Darwin' ]]; then
		local ioption='-i .bak'
	else
		local ioption='-i'
	fi

	cd "$WP_CORE_DIR"

	if [ ! -f wp-tests-config.php ]; then
		cp wp-tests-config-sample.php wp-tests-config.php
		sed $ioption "s/youremptytestdbnamehere/$DB_NAME/" wp-tests-config.php
		sed $ioption "s/yourusernamehere/$DB_USER/" wp-tests-config.php
		sed $ioption "s/yourpasswordhere/$DB_PASS/" wp-tests-config.php
		sed $ioption "s|localhost|${DB_HOST}|" wp-tests-config.php
	fi

	cd - > /dev/null
}

function install_db {
	if [ "$( type -t mysqladmin )" == '' ]; then
		echo "install_db failure: mysqladmin is not present"
		return 1
	fi

	# parse DB_HOST for port or socket references
	local PARTS=(${DB_HOST//\:/ })
	local DB_HOSTNAME=${PARTS[0]};
	local DB_SOCK_OR_PORT=${PARTS[1]};
	local EXTRA=""

	if ! [ -z "$DB_HOSTNAME" ] ; then
		if [ $(echo "$DB_SOCK_OR_PORT" | grep -e '^[0-9]\{1,\}$') ]; then
			EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
		elif ! [ -z "$DB_SOCK_OR_PORT" ] ; then
			EXTRA=" --socket=$DB_SOCK_OR_PORT"
		elif ! [ -z "$DB_HOSTNAME" ] ; then
			EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
		fi
	fi

	# drop the database if it exists
	mysqladmin drop -f "$DB_NAME" --silent --no-beep --user="$DB_USER" --password="$DB_PASS"$EXTRA || echo "$DB_NAME does not exist yet"

	# create database
	if ! mysqladmin create "$DB_NAME" --user="$DB_USER" --password="$DB_PASS"$EXTRA; then
		return 1
	fi

	echo "DB $DB_NAME created"
}

function find_phpunit_dirs {
	find $PATH_INCLUDES -name 'phpunit.xml*' ! -path '*/vendor/*' -name 'phpunit.xml*' -exec dirname {} \; > $TEMP_DIRECTORY/phpunitdirs
	if [ ! -z "$PATH_EXCLUDES_PATTERN" ]; then
		cat "$TEMP_DIRECTORY/phpunitdirs" | grep -E -v "$PATH_EXCLUDES_PATTERN" | cat - > "$TEMP_DIRECTORY/included-phpunitdirs"
		mv "$TEMP_DIRECTORY/included-phpunitdirs" "$TEMP_DIRECTORY/phpunitdirs"
	fi
	cat $TEMP_DIRECTORY/phpunitdirs
}

function run_phpunit_local {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
		return
	fi

	if ! check_should_execute 'phpunit'; then
		echo "Skipping PHPUnit as requested via DEV_LIB_SKIP / DEV_LIB_ONLY"
		return
	fi

	# TODO: This should eventually run unit tests only in the state of the DIFF_HEAD

	(
		echo "## phpunit"
		if [ -n "$( type -t phpunit )" ] && [ -n "$WP_TESTS_DIR" ]; then
			if [ -n "$PHPUNIT_CONFIG" ]; then
				phpunit $( if [ -n "$PHPUNIT_CONFIG" ]; then echo -c "$PHPUNIT_CONFIG"; fi )
			else
				for project in $( find_phpunit_dirs ); do
					(
						cd "$project"
						phpunit
					)
				done
			fi
		elif [ "$USER" != 'vagrant' ] && command -v vagrant >/dev/null 2>&1; then

			# Check if we're in Vagrant
			if [ ! -z "$VAGRANTFILE" ]; then
				cd $( dirname "$VAGRANTFILE" )
				VAGRANT_ROOT=$(pwd)
				if [ -e www/wp-content/themes/vip/plugins/vip-init.php ]; then
					ABSOLUTE_VAGRANT_PATH=/srv${PROJECT_DIR:${#VAGRANT_ROOT}}
				elif grep -q vvv Vagrantfile; then
					ABSOLUTE_VAGRANT_PATH=/srv${PROJECT_DIR:${#VAGRANT_ROOT}}
				fi
				cd - > /dev/null
			fi

			if [ ! -z "$ABSOLUTE_VAGRANT_PATH" ]; then
				VAGRANT_DEV_LIB_PATH=$ABSOLUTE_VAGRANT_PATH${DEV_LIB_PATH:${#PROJECT_DIR}}
				echo "Running phpunit in Vagrant"
				vagrant ssh -c "cd $ABSOLUTE_VAGRANT_PATH && export DIFF_BASE=$DIFF_BASE && export DIFF_HEAD=$DIFF_HEAD && export DEV_LIB_ONLY=phpunit && $VAGRANT_DEV_LIB_PATH/pre-commit"
			elif command -v vassh >/dev/null 2>&1; then
				echo "Running phpunit in vagrant via vassh..."
				vassh phpunit $( if [ -n "$PHPUNIT_CONFIG" ]; then echo -c "$PHPUNIT_CONFIG"; fi )
			else
				echo "Failed to run phpunit inside Vagrant"
			fi
		else
			echo "Skipping phpunit since not installed or WP_TESTS_DIR env missing"
		fi
	)
}

function run_phpunit_travisci {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
		return
	fi

	if [ "$( type -t phpunit )" == '' ]; then
		echo "Skipping PHPUnit because phpunit tool not installed"
		return
	fi

	if ! check_should_execute 'phpunit'; then
		echo "Skipping PHPUnit as requested via DEV_LIB_SKIP / DEV_LIB_ONLY"
		return
	fi
	if [ "$PROJECT_TYPE" != plugin ] && [ "$PROJECT_TYPE" != site ]; then
		echo "Skipping PHPUnit since only applicable to site or plugin project types"
		return
	fi
	echo
	echo "## PHPUnit tests"

	# Credentials on Travis
	DB_USER=root
	DB_PASS=''

	# Install the WordPress Unit Tests
	# Note: This is installed here instead of during the install phase because it is run last and can take longer
	if [ "$WP_INSTALL_TESTS" == 'true' ]; then
		if install_wp && install_test_suite && install_db; then
			echo "WP and unit tests installed"
		else
			echo "Failed to install unit tests"
		fi
	fi

	WP_TESTS_DIR=${WP_CORE_DIR}/tests/phpunit   # This is a bit of a misnomer: it is the *PHP* tests dir
	export WP_CORE_DIR
	export WP_TESTS_DIR

	if [ "$PROJECT_TYPE" == plugin ]; then
		INSTALL_PATH="$WP_CORE_DIR/src/wp-content/plugins/$PROJECT_SLUG"

		# Rsync the files into the right location
		mkdir -p "$INSTALL_PATH"
		rsync -a $(verbose_arg) --exclude .git/hooks --delete "$PROJECT_DIR/" "$INSTALL_PATH/"
		cd "$INSTALL_PATH"

		echo "Location: $INSTALL_PATH"
	elif [ "$PROJECT_TYPE" == site ]; then
		cd "$PROJECT_DIR"
	fi

	if [ "$( type -t after_wp_install )" != '' ]; then
		after_wp_install
	fi

	INITIAL_DIR=$(pwd)
	if [ -n "$PHPUNIT_CONFIG" ]; then
		phpunit $( if [ -n "$PHPUNIT_CONFIG" ]; then echo -c "$PHPUNIT_CONFIG"; fi )
	else
		for project in $( find_phpunit_dirs ); do
			(
				cd "$project"
				phpunit --stop-on-failure $( if [ "$project" == "$INITIAL_DIR" ]; then coverage_clover; fi )
			)
		done
	fi
	cd "$PROJECT_DIR"
}


## End functions for PHPUnit

function lint_js_files {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-js" ]; then
		return
	fi

	set -e

	# Run YUI Compressor.
	cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range > "$TEMP_DIRECTORY/paths-scope-js-yuicompressor"
	if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && [ ! -s "$TEMP_DIRECTORY/paths-scope-js-yuicompressor" ] && command -v java >/dev/null 2>&1 && check_should_execute 'yuicompressor'; then
		(
			echo "## YUI Compressor"
			cd "$LINTING_DIRECTORY"
			cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range | xargs java -jar "$YUI_COMPRESSOR_PATH" --nomunge --disable-optimizations -o /dev/null 2>&1
		)
	fi

	# Run JSHint.
	if [ -n "$JSHINT_CONFIG" ] && [ "$( type -t jshint )" != '' ] && check_should_execute 'jshint'; then
		(
			echo "## JSHint"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range | xargs jshint --reporter=unix --config="$JSHINT_CONFIG" $( if [ -n "$JSHINT_IGNORE" ]; then echo --exclude-path="$JSHINT_IGNORE"; fi ) > "$TEMP_DIRECTORY/jshint-report"; then
				if [ "$CHECK_SCOPE" == 'patches' ]; then
					cat "$TEMP_DIRECTORY/jshint-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-js"
				elif [ -s "$TEMP_DIRECTORY/jshint-report" ]; then
					cat "$TEMP_DIRECTORY/jshint-report"
					exit 1
				fi
			fi
		)
	fi

	# Run JSCS.
	if [ -n "$JSCS_CONFIG" ] && [ "$( type -t jscs )" != '' ] && check_should_execute 'jscs'; then
		(
			echo "## JSCS"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range | xargs jscs --max-errors -1 --reporter=inlinesingle --verbose --config="$JSCS_CONFIG" > "$TEMP_DIRECTORY/jscs-report"; then
				if [ "$CHECK_SCOPE" == 'patches' ]; then
					cat "$TEMP_DIRECTORY/jscs-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-js"
				elif [ -s "$TEMP_DIRECTORY/jscs-report" ]; then
					cat "$TEMP_DIRECTORY/jscs-report"
					exit 1
				fi
			fi
		)
	fi

	# Run ESLint.
	if [ -n "$ESLINT_CONFIG" ] && [ -e "$ESLINT_CONFIG" ] && [ -e "$(npm bin)/eslint" ] && check_should_execute 'eslint'; then
		(
			echo "## ESLint"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range | xargs "$(npm bin)/eslint" --max-warnings=-1 --quiet --format=compact --config="$ESLINT_CONFIG" --output-file "$TEMP_DIRECTORY/eslint-report"; then
				if [ "$CHECK_SCOPE" == 'patches' ]; then
					cat "$TEMP_DIRECTORY/eslint-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-js" | cut -c$( expr ${#LINTING_DIRECTORY} + 2 )-
					phpcs_status="${PIPESTATUS[1]}"
					if [[ $phpcs_status != 0 ]]; then
						return $phpcs_status
					fi
				elif [ -s "$TEMP_DIRECTORY/eslint-report" ]; then
					cat "$TEMP_DIRECTORY/eslint-report" | cut -c$( expr ${#LINTING_DIRECTORY} + 2 )-
					exit 1
				fi
			fi
		)
	fi
}

# @todo: This is wrong, as we should be doing `npm test` instead of calling `grunt qunit` directly.
function run_qunit {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-js" ] || ! check_should_execute 'grunt'; then
		return
	fi

	find $PATH_INCLUDES -name Gruntfile.js > "$TEMP_DIRECTORY/gruntfiles"
	if [ ! -z "$PATH_EXCLUDES_PATTERN" ]; then
		cat "$TEMP_DIRECTORY/gruntfiles" | grep -E -v "$PATH_EXCLUDES_PATTERN" | cat - > "$TEMP_DIRECTORY/included-gruntfiles"
		mv "$TEMP_DIRECTORY/included-gruntfiles" "$TEMP_DIRECTORY/gruntfiles"
	fi
	if [ ! -s "$TEMP_DIRECTORY/gruntfiles" ]; then
		return
	fi

	for gruntfile in $( cat "$TEMP_DIRECTORY/gruntfiles" ); do
		if ! grep -Eqs 'grunt\.loadNpmTasks.*grunt-contrib-qunit' "$gruntfile"; then
			continue
		fi
		echo "Gruntfile: $gruntfile"

		# @todo Skip if there the CHECK_SCOPE is limited, and the dirname($gruntfile) is not among paths-scope-js; make sure root works

		cd "$( dirname "$gruntfile" )"

		# Make sure Node packages are installed in this location. Ignore symlink.
		if [ -e package.json ] && [ ! -e node_modules -o -h node_modules ]; then
			npm install
		fi

		if [ -e "$(npm bin)/grunt" ]; then
			$(npm bin)/grunt qunit
		else
			grunt qunit
		fi

		cd - /dev/null
	done
}

function lint_xml_files {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-xml" ] || ! check_should_execute 'xmllint'; then
		return
	fi

	set -e

	echo "## XMLLINT"
	(
		cd "$LINTING_DIRECTORY"
		cat "$TEMP_DIRECTORY/paths-scope-xml" | remove_diff_range | xargs xmllint --noout
	)
}

function lint_php_files {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
		return
	fi

	set -e

	if check_should_execute 'phpsyntax'; then
		(
			echo "## PHP syntax check"
			cd "$LINTING_DIRECTORY"
			for php_file in $( cat "$TEMP_DIRECTORY/paths-scope-php" | remove_diff_range ); do
				php -lf "$php_file"
			done
		)
	fi

	# Check PHP_CodeSniffer WordPress-Coding-Standards.
	if [ "$( type -t phpcs )" != '' ] && ( [ -n "$WPCS_STANDARD" ] || [ -n "$PHPCS_RULESET_FILE" ] ) && check_should_execute 'phpcs'; then
		(
			echo "## PHP_CodeSniffer"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-php" | remove_diff_range | xargs phpcs -s --report-emacs="$TEMP_DIRECTORY/phpcs-report" --standard="$( if [ ! -z "$PHPCS_RULESET_FILE" ]; then echo "$PHPCS_RULESET_FILE"; else echo "$WPCS_STANDARD"; fi )" $( if [ -n "$PHPCS_IGNORE" ]; then echo --ignore="$PHPCS_IGNORE"; fi ); then
				if [ ! -s "$TEMP_DIRECTORY/phpcs-report" ]; then
					return 1
				elif [ "$CHECK_SCOPE" == 'patches' ]; then
					cat "$TEMP_DIRECTORY/phpcs-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-php" | cut -c$( expr ${#LINTING_DIRECTORY} + 2 )-
					phpcs_status="${PIPESTATUS[1]}"
					if [[ $phpcs_status != 0 ]]; then
						return $phpcs_status
					fi
				elif [ -s "$TEMP_DIRECTORY/phpcs-report" ]; then
					cat "$TEMP_DIRECTORY/phpcs-report" | cut -c$( expr ${#LINTING_DIRECTORY} + 2 )-
					exit 1
				fi
			fi
		)
	fi
}

function run_codeception {
	if [ "$CODECEPTION_CHECK" != 1 ] || ! check_should_execute 'codeception'; then
		return
	fi
	if [ -z "$CODECEPTION_CONFIG" ]; then
		echo "Skipping codeception since not configured"
		return
	fi

	# Download if it does not exist
	if [ ! -f "/tmp/codeception.phar" ];  then
		download http://codeception.com/codecept.phar /tmp/codecept.phar
	fi
	php /tmp/codecept.phar run
}

function check_execute_bit {
	if [ "$DISALLOW_EXECUTE_BIT" != 1 ] || ! check_should_execute 'executebit'; then
		return
	fi
	for FILE in $( cat "$TEMP_DIRECTORY/paths-scope" | remove_diff_range ); do
		if [ -x "$PROJECT_DIR/$FILE" ] && [ ! -d "$PROJECT_DIR/$FILE" ]; then
			echo "Error: Executable file being committed: $FILE. Do chmod -x on this."
			return 1
		fi
	done
}

function check_should_execute {
	if [ ! -z "$DEV_LIB_SKIP" ] && grep -sqi $1 <<< "$DEV_LIB_SKIP"; then
		return 1
	fi

	if [ ! -z "$DEV_LIB_ONLY" ] && ! grep -sqi $1 <<< "$DEV_LIB_ONLY"; then
		return 1
	fi

	return 0
}
