# ![wp-dev-lib](assets/logo.svg)

**Common tools to facilitate the development and testing of WordPress themes and plugins.**

Great for adding coding standards, linting and automated testing even to legacy projects since checks are applied to new code only by default.


## Installation

### Using [Composer](https://getcomposer.org)

```bash
composer require --dev xwp/wp-dev-lib
```

which will place it under `vendor/xwp/wp-dev-lib`.

### Using [npm](https://www.npmjs.com)

```bash
npm install --save-dev xwp/wp-dev-lib
```

which will place it under `node_modules/xwp/wp-dev-lib`.

### As [Git Submodule](https://git-scm.com/docs/git-submodule):

```bash
git submodule add -b master https://github.com/xwp/wp-dev-lib.git dev-lib
```

To update the library with the latest changes:

```bash
git submodule update --remote dev-lib
git add dev-lib
git commit -m "Update dev-lib"
```


## Configure the Git Pre-commit Hook

This tool comes with a [`pre-commit` hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_committing_workflow_hooks) which runs all linters, tests and checks before every commit to your project.

To add the hook with Composer we suggest to use [brainmaestro/composer-git-hooks](https://github.com/BrainMaestro/composer-git-hooks):

```bash
composer require --dev brainmaestro/composer-git-hooks
```

with the following configuration added to `composer.json`:

```json
{
  "extra": {
    "hooks": {
      "pre-commit": "./vendor/xwp/wp-dev-lib/scripts/pre-commit"
    }
  }
}
```

and two additional scripts that automatically setup the hooks during `composer install`:

```json
{
  "scripts": {
    "post-install-cmd": [
      "vendor/bin/cghooks add --no-lock"
    ],
    "post-update-cmd": [
      "vendor/bin/cghooks update"
    ],
  }
}
```

With `npm` we suggest to use [husky](https://www.npmjs.com/package/husky):

```bash
npm install husky --save-dev
```

with the following script added to your `package.json`:

```json
{
  "scripts": {
    "precommit": "./node_modules/wp-dev-lib/scripts/pre-commit"
  }
}
```

Alternatively, create a symlink at `.git/hooks/pre-commit` pointing to [`pre-commit`](scripts/pre-commit) using the bundled script:

```bash
./vendor/xwp/wp-dev-lib/scripts/install-pre-commit-hook.sh
```

To ensure that everyone on your team has the `pre-commit` hook added automatically, we recommend using the Composer or npm scripts as described above as the package managers will set up the `pre-commit` hook during the install phase.


## Pre-commit Tips

The default behaviour for the linters is to only report errors on lines that are within actual staged changes being committed. So remember to selectively stage the files (via `git add ...`) or better the patches (via `git add -p ...`).

### Skipping Checks

If you do need to disable the `pre-commit` hook for an extenuating circumstance (e.g. to commit a work in progress to share), you can use the `--no-verify` argument:

```bash
git commit --no-verify -m "WIP"
```

Alternatively, you can also selectively disable certain aspects of the `pre-commit` hook from being run via the `DEV_LIB_SKIP` environment variable. For example, when there is a change to a PHP file and there are PHPUnit tests included in a repo, but you've just changed a PHP comment or something that certainly won't cause tests to fail, you can make a commit and run all checks _except_ for PHPUnit via:

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

### Running Specific Checks

If you would like to run a specific check and ignore all other checks, then you can use `DEV_LIB_ONLY` environment variable. For example, you may want to only run PHPUnit before a commit:

```bash
DEV_LIB_ONLY=phpunit git commit
```

### Manually Invoking Pre-commit

Sometimes you may want to run the `pre-commit` checks manually to compare changes (`patches`) between branches much in the same way that Travis CI runs its checks. To compare the current staged changes against `master`, do:

```bash
DIFF_BASE=master ./vendor/xwp/wp-dev-lib/scripts/pre-commit
```

To compare the committed changes between `master` and the current branch:

```bash
DIFF_BASE=master DIFF_HEAD=HEAD ./vendor/xwp/wp-dev-lib/scripts/pre-commit
```


## Configure Code Linters

This tool comes with sample configuration files for the following linters:

- [`phpunit-plugin.xml`](sample-config/phpunit-plugin.xml) for [PHPUnit](https://phpunit.de)
- [`phpcs.xml`](sample-config/phpcs.xml) for [phpcs](https://github.com/squizlabs/PHP_CodeSniffer)
- [`.jshintrc`](sample-config/.jshintrc) and [`.jshintignore`](sample-config/.jshintignore) for [JSHint](http://jshint.com)
- [`.jscsrc`](sample-config/.jscsrc) for [JSCS](http://jscs.info)
- [`.eslintrc`](sample-config/.eslintrc) and [`.eslintignore`](sample-config/.eslintignore) for [ESLint](https://eslint.org)
- [`.editorconfig`](sample-config/.editorconfig) for [EditorConfig](http://editorconfig.org/).

Copy the files you need to the root directory of your project.

It is a best practice to install the various tools as dependencies in the project itself, pegging them at specific versions as required. This will ensure that the the tools will be repeatably installed across environments. When a tool is installed locally, it will be used instead of any globally-installed version.


### Suggested Composer Packages

Add these as development dependencies to your project:

```bash
composer require --dev package/name
```

- [`wp-coding-standards/wpcs`](https://packagist.org/packages/wp-coding-standards/wpcs) for adding [WordPress Coding Standards](https://make.wordpress.org/core/handbook/best-practices/coding-standards/) checks. Use together with the sample [`phpcs.xml`](sample-config/phpcs.xml) configuration.

- [`phpcompatibility/phpcompatibility-wp`](https://packagist.org/packages/phpcompatibility/phpcompatibility-wp) for checking PHP compatibility. Uses the [PHP version required](https://getcomposer.org/doc/04-schema.md#package-links) in the `composer.json` file. For example `composer require php '>=5.2'`.

- [`dealerdirect/phpcodesniffer-composer-installer`](https://packagist.org/packages/dealerdirect/phpcodesniffer-composer-installer) for automatically configuring the [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) coding sniffers.


## Travis CI

Copy the [`sample-config/.travis.yml`](sample-config/.travis.yml) file into the root of your repo:

```bash
cp ./vendor/xwp/wp-dev-lib/sample-config/.travis.yml .
```

Note that the bulk of the logic in this config file is located in [`travis.install.sh`](scripts/travis.install.sh), [`travis.script.sh`](scripts/travis.script.sh), and [`travis.after_script.sh`](scripts/travis.after_script.sh).

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

Also important to note that when the the `pre-commit` check runs, it will run the linters (PHPCS, JSHint, JSCS, etc) on the _staged changes_, not the files as they exist in the working tree. This means that you can use `git add -p` to interactively select changes to stage (which is a good general best practice in contrast to `git commit -a`), and _any code excluded from being staged will be ignored by the linter_. This is very helpful when you have some debug statements which you weren't intending to commit anyway (e.g. `print_r()` or `console.log()`).

With `CHECK_SCOPE=patches` and `CHECK_SCOPE=changed-files` available, it is much easier to integrate automated checks on existing projects that may have a lot of nonconforming legacy code. You can fix up a codebase incrementally line-by-line or file-by-file in the normal course of fixing bugs and adding new features.

If you want to disable the scope-limiting behavior, you can define `CHECK_SCOPE=all`.


## Environment Variables

You may customize the behavior of the `.travis.yml` and `pre-commit` hook by specifying a `.dev-lib` (formerly `.ci-env.sh`) Bash script in the root of the repo, for example:

```bash
DEFAULT_BASE_BRANCH=develop
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

Set `DEFAULT_BASE_BRANCH` to be whatever your default branch is in GitHub; this is use when doing diff-checks on changes in a branch build on Travis CI. The `PATH_INCLUDES` is especially useful when the dev-lib is used in the context of an entire site, so you can target just the themes and plugins that you're responsible for. For _excludes_, you can specify a `PHPCS_IGNORE` var and override the `.jshintignore`; there is a `PATH_EXCLUDES_PATTERN` as well.


## PHPUnit Code Coverage

The plugin-tailored [`phpunit.xml`](sample-config/phpunit-plugin.xml) has a `filter` in place to restrict PHPUnit's code coverage reporting to only look at the plugin's own PHP code, omitting the PHP from WordPress Core and other places that shouldn't be included. The `filter` greatly speeds up PHPUnit's execution. To get the code coverage report written out to a `code-coverage-report` directory:

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

The library includes a WordPress README [parser](scripts/class-wordpress-readme-parser.php) and [converter](scripts/generate-markdown-readme) to Markdown, so you don't have to manually keep your `readme.txt` on WordPress.org in sync with the `readme.md` you have on GitHub. The converter will also automatically recognize the presence of projects with Travis CI and include the status image in the markdown. Screenshots and banner images for WordPress.org are also automatically incorporated into the `readme.md`.

What is also included in this repo is an [`svn-push`](svn-push) to push commits from a GitHub repo to the WordPress.org SVN repo for the plugin. The `/assets/` directory in the root of the project will get automatically moved one directory above in the SVN repo (alongside `trunk`, `branches`, and `tags`). To use, include an `svn-url` file in the root of your repo and let this file contains he full root URL to the WordPress.org repo for plugin (don't include `trunk`).

The utilities in this project were first developed to facilitate development of [XWP](https://xwp.co/)'s [plugins](https://profiles.wordpress.org/xwp/).
