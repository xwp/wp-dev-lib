#!/bin/bash

set -e
shopt -s expand_aliases

function realpath {
	php -r 'echo realpath( $argv[1] );' "$1"
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

	if [ -z "$PROJECT_TYPE" ]; then
		if [ -e style.css ]; then
			PROJECT_TYPE=theme
		elif grep -isqE "^[     ]*\*[     ]*Plugin Name[     ]*:" "$PROJECT_DIR"/*.php; then
			PROJECT_TYPE=plugin
		else
			PROJECT_TYPE=unknown
		fi
	fi

	if [ ! -z "$LIMIT_TRAVIS_PR_CHECK_SCOPE" ]; then
		echo "LIMIT_TRAVIS_PR_CHECK_SCOPE is obsolete; use CHECK_SCOPE env var instead" 1>&2
		return 1
	fi
	CHECK_SCOPE=${CHECK_SCOPE:-changed-files} # 'all', 'changed-files', 'patches'

	if [ "$TRAVIS" == true ]; then
		if [[ "$TRAVIS_PULL_REQUEST" != 'false' ]]; then
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

	PHPCS_DIR=${PHPCS_DIR:-/tmp/phpcs}
	PHPCS_PHAR_URL=https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar
	PHPCS_RULESET_FILE=$( upsearch phpcs.ruleset.xml )
	PHPCS_IGNORE=${PHPCS_IGNORE:-'vendor/*'}
	PHPCS_GIT_TREE=${PHPCS_GIT_TREE:-master}
	PHPCS_GITHUB_SRC=${PHPCS_GITHUB_SRC:-squizlabs/PHP_CodeSniffer}

	if [ -z "$PHPUNIT_CONFIG" ]; then
		if [ -e phpunit.xml ]; then
			PHPUNIT_CONFIG=phpunit.xml
		elif [ -e phpunit.xml.dist ]; then
			PHPUNIT_CONFIG=phpunit.xml.dist
		fi
	fi

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
	else
		JSHINT_IGNORE="$DEV_LIB_PATH/.jshintignore"
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
			DIFF_ARGS="--staged $DIFF_BASE"
		fi
	elif [ "$DIFF_HEAD" == 'WORKING' ]; then
		DIFF_ARGS="$DIFF_BASE"
	else
		DIFF_ARGS="$DIFF_BASE...$DIFF_HEAD"
	fi

	if [ "$CHECK_SCOPE" == 'patches' ]; then
		git diff --diff-filter=AM --no-prefix --unified=0 "$DIFF_ARGS" -- $PATH_INCLUDES | php "$DEV_LIB_PATH/diff-tools/parse-diff-ranges.php" > "$TEMP_DIRECTORY/paths-scope"
	elif [ "$CHECK_SCOPE" == 'changed-files' ]; then
		git diff "$DIFF_ARGS" --name-only $PATH_INCLUDES > "$TEMP_DIRECTORY/paths-scope"
	else
		git ls-files -- $PATH_INCLUDES > "$TEMP_DIRECTORY/paths-scope"
	fi

	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.php(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-php"
	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.(js|json|jshintrc)(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-js"
	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.(css|scss)(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-scss"
	cat "$TEMP_DIRECTORY/paths-scope" | grep -E '\.(xml|svg|xml.dist)(:|$)' | cat - > "$TEMP_DIRECTORY/paths-scope-xml"

	# Gather the proper states of files to run through linting (this won't apply to phpunit)
	if [ "$DIFF_HEAD" != 'working' ]; then
		LINTING_DIRECTORY="$(realpath $TEMP_DIRECTORY)/index"
		mkdir -p "$LINTING_DIRECTORY"

		for path in $( cat "$TEMP_DIRECTORY/paths-scope" | remove_diff_range ); do
			# Skip submodules
			if [ -d "$path" ]; then
				continue
			fi

			mkdir -p "$LINTING_DIRECTORY/$(dirname "$path")"
			if [ "$DIFF_HEAD" == 'STAGE' ]; then
				git show :"$path" > "$LINTING_DIRECTORY/$path"
			else
				git show "$DIFF_HEAD":"$path" > "$LINTING_DIRECTORY/$path"
			fi
		done
	else
		LINTING_DIRECTORY="$PROJECT_DIR"
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
	for var in JSHINT_CONFIG LINTING_DIRECTORY TEMP_DIRECTORY DEV_LIB_PATH PROJECT_DIR PROJECT_SLUG PATH_INCLUDES PROJECT_TYPE CHECK_SCOPE DIFF_BASE DIFF_HEAD PHPCS_DIR PHPCS_GITHUB_SRC PHPCS_GIT_TREE PHPCS_RULESET_FILE PHPCS_IGNORE WPCS_DIR WPCS_GITHUB_SRC WPCS_GIT_TREE WPCS_STANDARD WP_CORE_DIR WP_TESTS_DIR YUI_COMPRESSOR_CHECK DISALLOW_EXECUTE_BIT CODECEPTION_CHECK JSCS_CONFIG JSCS_CONFIG ENV_FILE ENV_FILE DIFF_BASE DIFF_HEAD CHECK_SCOPE IGNORE_PATHS HELP VERBOSE DB_HOST DB_NAME DB_USER DB_PASS WP_INSTALL_TESTS; do
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

function install_tools {
	# Install PHP tools.
	if [ -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
		install_phpcs

		# Install the WordPress Unit Tests
		if [ "$WP_INSTALL_TESTS" == 'true' ]; then
			if install_wp && install_test_suite && install_db; then
			    echo "WP and unit tests installed"
			else
				echo "Failed to install unit tests"
			fi
		fi
	fi

	# Install JS tools.
	if [ -s "$TEMP_DIRECTORY/paths-scope-js" ]; then

		# Install JSHint
		if ! command -v jshint >/dev/null 2>&1; then
			echo "Installing JSHint"
			npm install -g jshint
		fi

		# Install jscs
		if [ -n "$JSCS_CONFIG" ] && [ -e "$JSCS_CONFIG" ] && ! command -v jscs >/dev/null 2>&1; then
			echo "JSCS"
			npm install -g jscs
		fi

		# @todo ESLint

		# YUI Compressor
		if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && command -v java >/dev/null 2>&1; then
			if [ ! -e "$YUI_COMPRESSOR_PATH" ]; then
				download https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar "$YUI_COMPRESSOR_PATH"
			fi
		fi
	fi

	# Install Composer
	if [ -e composer.json ]; then
		curl -s http://getcomposer.org/installer | php && php composer.phar install
	fi
}

function install_phpcs {
	if [ -z "$WPCS_STANDARD" ]; then
		echo "Skipping PHPCS since WPCS_STANDARD (and PHPCS_RULESET_FILE) is empty." 1>&2
		return
	fi

	if ! command -v phpunit >/dev/null 2>&1; then
		echo "Downloading PHPUnit phar"
		download https://phar.phpunit.de/phpunit.phar /tmp/phpunit.phar
		chmod +x /tmp/phpunit.phar
		alias phpunit='/tmp/phpunit.phar'
	fi

	if ! command -v phpcs >/dev/null 2>&1; then
		echo "Downloading PHPCS phar"
		download "$PHPCS_PHAR_URL" /tmp/phpcs.phar
		chmod +x /tmp/phpcs.phar
		alias phpcs='/tmp/phpcs.phar'
	fi

	if ! phpcs -i | grep -q 'WordPress'; then
		git clone -b "$WPCS_GIT_TREE" "https://github.com/$WPCS_GITHUB_SRC.git" $WPCS_DIR
		# @todo Pull periodically
		phpcs --config-set installed_paths $WPCS_DIR
	fi
}

## Begin functions for phpunit ###########################

function install_wp {

	if [ -d "$WP_CORE_DIR" ]; then
		return 0
	fi
	if ! command -v svn >/dev/null 2>&1; then
		echo "install_wp failure: svn is not installed"
		return 1
	fi

	if [ "$WP_VERSION" == 'latest' ]; then
		local TAG=$( svn ls https://develop.svn.wordpress.org/tags | tail -n 1 | sed 's:/$::' )
		local SVN_URL="https://develop.svn.wordpress.org/tags/$TAG/"
	elif [ "$WP_VERSION" == 'trunk' ]; then
		local SVN_URL=https://develop.svn.wordpress.org/trunk/
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

}

function install_db {
	if ! command -v mysqladmin >/dev/null 2>&1; then
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
	mysqladmin create "$DB_NAME" --user="$DB_USER" --password="$DB_PASS"$EXTRA

	echo "DB $DB_NAME created"
}

function run_phpunit_local {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-php" ] || [ -z "$PHPUNIT_CONFIG" ]; then
		return
	fi

	(
		echo "## phpunit"
		if [ "$USER" != 'vagrant' ]; then

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
				echo "Running phpunit in Vagrant"
				vagrant ssh -c "cd $ABSOLUTE_VAGRANT_PATH && phpunit -c $PHPUNIT_CONFIG"
			elif command -v vassh >/dev/null 2>&1; then
				echo "Running phpunit in vagrant via vassh..."
				vassh phpunit -c "$PHPUNIT_CONFIG"
			fi
		elif ! command -v phpunit >/dev/null 2>&1;then
			echo "Skipping phpunit since not installed"
		elif [ -z "$WP_TESTS_DIR" ]; then
			echo "Skipping phpunit since WP_TESTS_DIR env missing"
		else
			phpunit -c "$PHPUNIT_CONFIG"
		fi
	)
}

function run_phpunit_travisci {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-php" ] || [ -z "$PHPUNIT_CONFIG" ]; then
		return
	fi

	echo
	echo "## PHPUnit tests"

	if [ "$PROJECT_TYPE" != plugin ]; then
		echo "Skipping since currently only applies to plugins"
		return
	fi

	if [ "$PROJECT_TYPE" == plugin ]; then
		INSTALL_PATH="$WP_CORE_DIR/src/wp-content/plugins/$PROJECT_SLUG"
	fi

	WP_TESTS_DIR=${WP_CORE_DIR}/tests/phpunit   # This is a bit of a misnomer: it is the *PHP* tests dir
	export WP_CORE_DIR
	export WP_TESTS_DIR

	# Rsync the files into the right location
	mkdir -p "$INSTALL_PATH"
	rsync -a $(verbose_arg) --exclude .git/hooks --delete "$PROJECT_DIR/" "$INSTALL_PATH/"
	cd "$INSTALL_PATH"

	# @todo Remove untracked files when not working with? In Travis this is not applicable.
	# if [ "$DIFF_HEAD" != 'WORKING' ]; then
	# 	git clean -d --force --quiet
	# fi
	# if [ "$DIFF_HEAD" == 'STAGE' ]; then
	# 	git checkout .
	# fi
	# git status

	# @todo Delete files that are not in Git?
	echo "Location: $INSTALL_PATH"

	if ! command -v phpunit >/dev/null 2>&1; then
		echo "Downloading PHPUnit phar"
		download https://phar.phpunit.de/phpunit.phar /tmp/phpunit.phar
		chmod +x /tmp/phpunit.phar
		alias phpunit='/tmp/phpunit.phar'
	fi

	# Run the tests
	phpunit $(verbose_arg) --configuration "$PHPUNIT_CONFIG"
	cd - > /dev/null
}


## End functions for PHPUnit

function lint_js_files {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-js" ]; then
		return
	fi

	set -e

	# Run JSHint.
	if [ -n "$JSHINT_CONFIG" ] && command -v jshint >/dev/null 2>&1; then
		(
			echo "## JSHint"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range | xargs jshint --reporter=unix --config="$JSHINT_CONFIG" $( if [ -n "$JSHINT_IGNORE" ]; then echo --exclude-path "$JSHINT_IGNORE"; fi ) > "$TEMP_DIRECTORY/jshint-report"; then
				cat "$TEMP_DIRECTORY/jshint-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-js"
			fi
		)
	fi

	# Run JSCS.
	if [ -n "$JSCS_CONFIG" ] && command -v jscs >/dev/null 2>&1; then
		(
			echo "## JSCS"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range | xargs jscs --reporter=inlinesingle --verbose --config="$JSCS_CONFIG" > "$TEMP_DIRECTORY/jscs-report"; then
				cat "$TEMP_DIRECTORY/jscs-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-js"
			fi
		)
	fi

	# Run YUI Compressor.
	if [ "$YUI_COMPRESSOR_CHECK" == 1 ] && command -v java >/dev/null 2>&1; then
		(
			echo "## YUI Compressor"
			cd "$LINTING_DIRECTORY"
			java -jar "$YUI_COMPRESSOR_PATH" -o /dev/null $(cat "$TEMP_DIRECTORY/paths-scope-js" | remove_diff_range) 2>&1
		)
	fi
}

function lint_php_files {
	if [ ! -s "$TEMP_DIRECTORY/paths-scope-php" ]; then
		return
	fi

	set -e

	(
		echo "## PHP syntax check"
		cd "$LINTING_DIRECTORY"
		for php_file in $( cat "$TEMP_DIRECTORY/paths-scope-php" | remove_diff_range ); do
			php -lf "$php_file"
		done
	)

	# Check PHP_CodeSniffer WordPress-Coding-Standards.
	if command -v phpcs >/dev/null 2>&1 && ( [ -n "$WPCS_STANDARD" ] || [ -n "$PHPCS_RULESET_FILE" ] ); then
		(
			echo "## PHP_CodeSniffer"
			cd "$LINTING_DIRECTORY"
			if ! cat "$TEMP_DIRECTORY/paths-scope-php" | remove_diff_range | xargs phpcs -s --report-emacs="$TEMP_DIRECTORY/phpcs-report" --standard="$( if [ ! -z "$PHPCS_RULESET_FILE" ]; then echo "$PHPCS_RULESET_FILE"; else echo "$WPCS_STANDARD"; fi )"; then
				cat "$TEMP_DIRECTORY/phpcs-report" | php "$DEV_LIB_PATH/diff-tools/filter-report-for-patch-ranges.php" "$TEMP_DIRECTORY/paths-scope-php" | cut -c$( expr ${#LINTING_DIRECTORY} + 2 )-
				phpcs_status="${PIPESTATUS[1]}"
				if [[ $phpcs_status != 0 ]]; then
					return $phpcs_status
				fi
			fi
		)
	fi
}

function run_codeception {
	if [ "$CODECEPTION_CHECK" != 1 ]; then
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
	if [ "$DISALLOW_EXECUTE_BIT" != 1 ]; then
		return
	fi
	for FILE in $( cat "$TEMP_DIRECTORY/paths-scope" | remove_diff_range ); do
		if [ -x "$PROJECT_DIR/$FILE" ] && [ ! -d "$PROJECT_DIR/$FILE" ]; then
			echo "Error: Executable file being committed: $FILE. Do chmod -x on this."
			return 1
		fi
	done
}
