wp-dev-lib
==========

**Common tools to facilitate the development and testing of WordPress themes and plugins**

## Installation

### Install as submodule

To install as Git submodule (recommended):

```bash
git submodule add -b master https://github.com/xwp/wp-dev-lib.git dev-lib
```

To **update** the library with the latest changes:

```bash
git submodule update --remote dev-lib
git add dev-lib
git commit -m "Update dev-lib"
```

To install the pre-commit hook, symlink to [`pre-commit`](pre-commit) from your project's `.git/hooks/pre-commit`, you can use the bundled script to do this:

```bash
./dev-lib/install-pre-commit-hook.sh
```

Also symlink (or copy) the [`.jshintrc`](.jshint), [`.jshintignore`](.jshintignore), [`.jscsrc`](.jscsrc), [`phpcs.xml`](phpcs.xml), and [`phpunit-plugin.xml`](phpunit-plugin.xml) (note the PHPUnit config will need its paths modified if it is copied instead of symlinked):

```bash
ln -s dev-lib/phpunit-plugin.xml phpunit.xml.dist && git add phpunit.xml.dist # (if working with a plugin)
ln -s dev-lib/phpcs.xml . && git add phpcs.xml
ln -s dev-lib/.jshintrc . && git add .jshintrc
ln -s dev-lib/.jscsrc . && git add .jscsrc
ln -s dev-lib/.eslintrc . && git add .eslintrc
ln -s dev-lib/.eslintignore . && git add .eslintignore
ln -s dev-lib/.editorconfig . && git add .editorconfig
cp dev-lib/.jshintignore . && git add .jshintignore # don't use symlink for this
```

For ESLint, you'll also likely want to make `eslint` as a dev dependency for your NPM package:

```bash
npm init # if you don't have a package.json already
npm install --save-dev eslint
git add package.json
echo 'node_modules' >> .gitignore
git add .gitignore
```

See below for how to configure your `.travis.yml`.

### Install via symlink (non-submodule)

Often installing as a submodule is not viable, for example when contributing to an existing project, such as WordPress Core itself.  If you don't want to install as a submodule you can instead just clone the repo somewhere on your system and then just add the `pre-commit` hook (see below) to symlink to this location, for example:

```bash
git clone https://github.com/xwp/wp-dev-lib.git ~/Projects/wp-dev-lib
~/Projects/wp-dev-lib/install-pre-commit-hook.sh /path/to/my-plugin
```

For the Travis CI checks, the `.travis.yml` copied and committed to the repo (see below) will clone the repo into the `dev-lib` directory if it doesn't exist (or whatever your `DEV_LIB_PATH` environment variable is set to).

To install the [`.jshintrc`](.jshint), [`.jshintignore`](.jshintignore), [`.jscsrc`](.jscsrc), and (especially optionally) [`phpcs.xml`](phpcs.xml), copy the files into the repo root (as opposed to creating symlinks, as when installing via submodule).

To install dev-lib for all themes and plugins that don't already have a `pre-commit` hook installed, and to upgrade the dev-lib for any submodule installations, you can run the bundled script [`install-upgrade-pre-commit-hook.sh`](install-upgrade-pre-commit-hook.sh) which will look for any repos in the current directory tree and attempt to auto-install. For example:

```bash
git clone https://github.com/xwp/wp-dev-lib.git ~/Shared/dev-lib
cd ~/Shared/dev-lib
./install-shared-pre-commit-hook.sh ~/Projects/wordpress
```

## Travis CI

Copy the [`.travis.yml`](.travis.yml) file into the root of your repo:

```bash
cp dev-lib/.travis.yml .
```

Note that the bulk of the logic in this config file is located in [`travis.install.sh`](travis.install.sh), [`travis.script.sh`](travis.script.sh), and [`travis.after_script.sh`](travis.after_script.sh), so there is minimal chance for the `.travis.yml` to diverge from upstream. Additionally, since each project likely may need to have unique environment targets (such as which PHP versions, whether multisite is relevant, etc), it makes sense that `.travis.yml` gets forked.

**Important Note:** The format of the `.travis.yml` changed in January 2016, so make sure that the file is updated to reflect [the changes](https://github.com/xwp/wp-dev-lib/pull/127/files#diff-354f30a63fb0907d4ad57269548329e3).

Edit the `.travis.yml` to change the target PHP version(s) and WordPress version(s) you need to test for and also whether you need to test on multisite or not:

```yml
php:
    - 5.3
    - 7.0

env:
    - WP_VERSION=latest WP_MULTISITE=0
    - WP_VERSION=latest WP_MULTISITE=1
    - WP_VERSION=trunk WP_MULTISITE=0
    - WP_VERSION=trunk WP_MULTISITE=1
```

Having more variations here is good for open source plugins, which are free for Travis CI. However, if you are using Travis CI with a private repo you probably want to limit the jobs necessary to complete a build. So if your production environment is running PHP 5.5, is on the latest stable version of WordPress, and is not multisite, then your `.travis.yml` could just be:

```yml
php:
    - 5.5

env:
    - WP_VERSION=4.0 WP_MULTISITE=0
```

This will greatly speed up the time build time, giving you quicker feedback on your pull request status, and prevent your Travis build queue from getting too backlogged.

### Limiting Scope of Checks

A barrier of entry for adding automated code quality checks to an existing project is that there may be _a lot_ of issues in your codebase that get reported initially. So to get passing builds you would then have a major effort to clean up your codebase to make it conforming to PHP_CodeSniffer, JSHint, and other tools. This is not ideal and can be problematic in projects with a lot of activity since these changes will add lots of conflicts with others' pull requests.

To get around this issue, there is now an environment variable available for configuration: `CHECK_SCOPE`. By default its value is `patches` which means that when a `pre-commit` runs or Travis runs a build on a pull request or commit, the checks will be restricted in their scope to _only report on issues occurring in the changed lines (patches)_. Checking patches is the most useful, but `CHECK_SCOPE=changed-files` can be added in the project config so that the checks will be limited to the entirety of any file that has been modified.

Also important to note that when the the `pre-commit` check runs, it will run the linters (PHPCS, JSHint, JSCS, etc) on the *staged changes*, not the files as they exist in the working tree. This means that you can use `git add -p` to interactively select changes to stage (which is a good general best practice in contrast to `git commit -a`), and *any code excluded from being staged will be ignored by the linter*. This is very helpful when you have some debug statements which you weren't intending to commit anyway (e.g. `print_r()` or `console.log()`).

With `CHECK_SCOPE=patches` and `CHECK_SCOPE=changed-files` available, it is much easier to integrate automated checks on existing projects that may have a lot of nonconforming legacy code. You can fix up a codebase incrementally line-by-line or file-by-file in the normal course of fixing bugs and adding new features.

If you want to disable the scope-limiting behavior, you can define `CHECK_SCOPE=all`.

## Environment Variables

You may customize the behavior of the `.travis.yml` and `pre-commit` hook by
specifying a `.dev-lib` (formerly `.ci-env.sh`) Bash script in the root of the repo, for example:

```bash
PHPCS_GITHUB_SRC=xwp/PHP_CodeSniffer
PHPCS_GIT_TREE=phpcs-patch
PHPCS_IGNORE='tests/*,includes/vendor/*' # See also PATH_INCLUDES below
WPCS_GIT_TREE=develop
WPCS_STANDARD=WordPress-Extra
DISALLOW_EXECUTE_BIT=1
YUI_COMPRESSOR_CHECK=1
PATH_INCLUDES="docroot/wp-content/plugins/acme-* docroot/wp-content/themes/acme-*"
CHECK_SCOPE=patches
```

The `PATH_INCLUDES` is especially useful when the dev-lib is used in the context of an entire site, so you can target just the themes and plugins that you're responsible for. For *excludes*, you can specify a `PHPCS_IGNORE` var and override the `.jshintignore` (it would be better to have a `PATH_EXCLUDES` as well).

## Pre-commit tips

As noted above in Limiting Scope of Checks, the default behavior for the linters is to only report errors on lines that lie within actual staged changes being committed. So remember to selectively stage the files (via `git add ...`) or better the patches (via `git add -p ...`).

### Skipping Checks

If you do need to disable the `pre-commit` hook for an extenuating circumstance (e.g. to commit a work in progress to share), you can use the `--no-verify` argument:

```bash
git commit --no-verify -m "WIP"
```

Alternatively, you can also selectively disable certain aspects of the `pre-commit` hook from being run via the `DEV_LIB_SKIP` environment variable. For example, when there is a change to a PHP file and there are PHPUnit tests included in a repo, but you've just changed a PHP comment or something that certainly won't cause tests to fail, you can make a commit and run all checks *except* for PHPUnit via:

```bash
DEV_LIB_SKIP=phpunit git commit
```

You can string along multiple checks to skip via commas:

```bash
DEV_LIB_SKIP=composer,phpunit,phpcs,yuicompressor,jscs,jshint,codeception,executebit git commit
```

Naturally you'd want to create a Git alias for whatever you use most often, for example:

```bash
git config --global alias.commit-without-phpunit '!DEV_LIB_SKIP="$DEV_LIB_SKIP,phpunit" git commit'
```

Which would allow you to then do the following (with Bash [tab completion](https://git-scm.com/book/en/v1/Git-Basics-Tips-and-Tricks#Auto-Completion) even):

```bash
git commit-without-phpunit
```

Aside, you can [skip Travis CI builds](https://docs.travis-ci.com/user/customizing-the-build/#Skipping-a-build) by including `[ci skip]` in the commit message.

### Running specific checks

If you would like to run a specific check and ignore all other checks, then you can use `DEV_LIB_ONLY` environment variable. For example, you may want to only run PHPUnit before a commit:

```bash
DEV_LIB_ONLY=phpunit git commit
```

### Manually invoking `pre-commit`

Sometimes you may want to run the `pre-commit` checks manually to compare changes (`patches`) between branches much in the same way that Travis CI runs its checks. To compare the current staged changes against `master`, do:

```bash
DIFF_BASE=master .git/hooks/pre-commit
```

To compare the committed changes between `master` and the current branch:

```bash
DIFF_BASE=master DIFF_HEAD=HEAD .git/hooks/pre-commit
```

## PHPUnit Code Coverage

The plugin-tailored [`phpunit.xml`](phpunit-plugin.xml) has a `filter` in place to restrict PHPUnit's code coverage reporting to only look at the plugin's own PHP code, omitting the PHP from WordPress Core and other places that shouldn't be included. The `filter` greatly speeds up PHPUnit's execution. To get the code coverage report written out to a `code-coverage-report` directory:

```bash
phpunit --coverage-html code-coverage-report/
```

Then you can open up the `index.html` in that directory to learn about your plugin's code coverage.

## Codeception

Bootstrap Codeception by:
```bash
wget -O /tmp/codecept.phar http://codeception.com/codecept.phar
php /tmp/codecept.phar bootstrap
```

Then update Acceptance tests configuration to reflect your own environment settings:
```bash
vim tests/acceptance.suite.yml
```

You can generate your first test, saved to `tests/acceptance/WelcomeCept.php` by:
```bash
php /tmp/codecept.phar generate:cept acceptance Welcome
```

## Gitter

Create an empty `.gitter` file in the root of your repo and a [Gitter](https://gitter.im) chat badge will be added to your project's README.

[![Join the chat](https://badges.gitter.im/Join%20Chat.svg)](#)

## Plugin Helpers

The library includes a WordPress README [parser](class-wordpress-readme-parser.php) and [converter](generate-markdown-readme) to Markdown, so you don't have to manually keep your `readme.txt` on WordPress.org in sync with the `readme.md` you have on GitHub. The converter will also automatically recognize the presence of projects with Travis CI and include the status image in the markdown. Screenshots and banner images for WordPress.org are also automatically incorporated into the `readme.md`.

What is also included in this repo is an [`svn-push`](svn-push) to push commits from a GitHub repo to the WordPress.org SVN repo for the plugin. The `/assets/` directory in the root of the project will get automatically moved one directory above in the SVN repo (alongside `trunk`, `branches`, and `tags`). To use, include an `svn-url` file in the root of your repo and let this file contains he full root URL to the WordPress.org repo for plugin (don't include `trunk`).

The utilities in this project were first developed to facilitate development of [XWP](https://xwp.co/)'s [plugins](https://profiles.wordpress.org/xwp/).
