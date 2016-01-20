wp-dev-lib
==========

**Common tools to facilitate the development and testing of WordPress themes and plugins**

## Installation

It is intended that this repo be included in plugin repo via git-submodule in a `dev-lib/` directory. To **add** it to your repo, do:

```bash
git submodule add https://github.com/xwp/wp-dev-lib.git dev-lib
```

To **update** the library with the latest changes:

```bash
git submodule update --remote dev-lib
git add dev-lib
git commit -m "Update dev-lib"
```

If Travis CI is not available (below) and you don't want to install the submodule, you can instead just clone the repo somewhere on your system and then just add the `pre-commit` hook (also below) to symlink to this location, for example:

```bash
git clone https://github.com/xwp/wp-dev-lib.git ~/shared/dev-lib
cd my-plugin/.git/hooks
ln -s ~/shared/dev-lib/pre-commit
```

Or to install dev-lib for all plugins that don't already have a `pre-commit` hook installed via symlinks (and using symlinks here is important, so it can find the path to the dev-lib repo):

```bash
git clone https://github.com/xwp/wp-dev-lib.git ~/shared/dev-lib
for plugin_git_dir in $( find . -type d -path '*/wp-content/plugins/*/.git' ); do
    if [ ! -e "$plugin_git_dir/hooks/pre-commit" ]; then
        ln -s ~/shared/dev-lib/pre-commit $plugin_git_dir/hooks/pre-commit
    fi
done
```

## Travis CI

Copy the [`.travis.yml`](.travis.yml) file into the root of your repo:

```bash
cp dev-lib/.travis.yml .
```

Note that the builk of the logic in this config file is located in [`travis.install.sh`](travis.install.sh), [`travis.script.sh`](travis.script.sh), and [`travis.after_script.sh`](travis.after_script.sh), so there is minimal chance for the `.travis.yml` to diverge from upstream. Additionally, since each project likely may need to have unique environment targets (such as which PHP versions, whether multisite is relevant, etc), it makes sense that `.travis.yml` gets forked.

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

To get around this issue, there is now an environment variable available for configuration: `CHECK_SCOPE`. By default its value is `patches` which means that when a `pre-commit` runs or a pull request is opened, the checks will be restricted in their scope to _only report on issues occurring in the changed lines (patches)_. What's more is that `CHECK_SCOPE=changed-files` can be added in the project config so that the checks will be limited _only to the files that have been modified_.

With `CHECK_SCOPE=patches` and `CHECK_SCOPE=changed-files` available, it is much easier to integrate automated checks on existing projects that may have a lot of nonconforming legacy code. You can fix up a codebase incrementally line-by-line or file-by-file in the normal course of fixing bugs and adding new features.

If you want to disable the scope-limiting behavior, you can define `CHECK_SCOPE=all`.

## Symlinks

Next, after configuring your `.travis.yml`, symlink the [`.jshintrc`](.jshint), [`.jshintignore`](.jshintignore), [`.jscsrc`](.jscsrc), and (especially optionally) [`phpcs.ruleset.xml`](phpcs.ruleset.xml):

```bash
ln -s dev-lib/phpunit-plugin.xml phpunit.xml.dist && git add phpunit.xml.dist # (if working with a plugin)
ln -s dev-lib/.jshintrc . && git add .jshintrc
ln -s dev-lib/.jshintignore . && git add .jshintignore
ln -s dev-lib/.jscsrc . && git add .jscsrc
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

## Pre-commit Hook

Symlink to [`pre-commit`](pre-commit) from your project's `.git/hooks/pre-commit`:

```bash
cd .git/hooks && ln -s ../../dev-lib/pre-commit . && cd -
```

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

## Plugin Helpers

The library includes a WordPress README [parser](class-wordpress-readme-parser.php) and [converter](generate-markdown-readme) to Markdown, so you don't have to manually keep your `readme.txt` on WordPress.org in sync with the `readme.md` you have on GitHub. The converter will also automatically recognize the presence of projects with Travis CI and include the status image in the markdown. Screenshots and banner images for WordPress.org are also automatically incorporated into the `readme.md`.

What is also included in this repo is an [`svn-push`](svn-push) to push commits from a GitHub repo to the WordPress.org SVN repo for the plugin. The `/assets/` directory in the root of the project will get automatically moved one directory above in the SVN repo (alongside `trunk`, `branches`, and `tags`). To use, include an `svn-url` file in the root of your repo and let this file contains he full root URL to the WordPress.org repo for plugin (don't include `trunk`).

The utilities in this project were first developed to facilitate development of [XWP](https://xwp.co/)'s [plugins](https://profiles.wordpress.org/xwp/).
