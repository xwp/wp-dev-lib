# ![wp-dev-lib](logo.svg)

**Common tools to facilitate the development and testing of WordPress themes and plugins**

## Installation

Add it as a developer dependancy to your project using [Composer](https://getcomposer.org):

```bash
composer require --dev xwp/wp-dev-lib
```

which will place it under `vendor/xwp/wp-dev-lib`.

Or using [npm](https://www.npmjs.com):

```bash
npm install --save-dev xwp/wp-dev-lib
```

which will place it under `node_modules/xwp/wp-dev-lib`.


## Configure the Git Pre-commit Hook

This tool comes with a [pre-commit hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_committing_workflow_hooks) which runs all linters, tests and checks before every commit to your project.

To add the hook with Composer we suggest to use [brainmaestro/composer-git-hooks](https://github.com/BrainMaestro/composer-git-hooks) and the following config added to `composer.json`:

```json
{
  "extra": {
    "hooks": {
      "pre-commit": "scripts/test"
    }
  }
}
```

With `npm` we suggest to use [husky](https://www.npmjs.com/package/husky) with the following script added to your `package.json`:

```json
{
  "scripts": {
    "precommit": "./node_modules/wp-dev-lib/pre-commit"
  },
}
```


## Configure Code Linters

This tool comes with sample configuration files fow the following linters:

- [`phpunit-plugin.xml`](sample-config/phpunit-plugin.xml) for PHPUnit
- [`phpcs.xml`](sample-config/phpcs.xml) for phpcs
- [`.jshintrc`](sample-config/.jshintrc) and [`.jshintignore`](sample-config/.jshintignore) for JSHint
- [`.jscsrc`](sample-config/.jscsrc) for JSCS
- [`.eslintrc`](sample-config/.eslintrc) and [`.eslintignore`](sample-config/.eslintignore) for ESLint
- [`.editorconfig`](sample-config/.editorconfig) for [EditorConfig](http://editorconfig.org/).

Copy the files you need to the root directory of your project.

It is a best practice to install the various tools as dependencies in the project itself, pegging them at specific versions as required. This will ensure that the the tools will be repeatably installed across environments. When a tool is installed locally, it will be used instead of any globally-installed version. To install packages locally, for example:

```bash
npm init # if you don't have a package.json already
npm install --save-dev eslint jshint jscs grunt-cli
git add package.json
echo 'node_modules' >> .gitignore

composer init # if you don't have a composer.json already
composer require php '>=5.2' # increase this if you need
composer require --dev "wp-coding-standards/wpcs=*"
composer require --dev "wimg/php-compatibility=*"
composer require --dev dealerdirect/phpcodesniffer-composer-installer
echo 'vendor' >> .gitignore

git add .gitignore
```

See below for how to configure your `.travis.yml`.


## Travis CI

Copy the [`sample-config/.travis.yml`](sample-config/.travis.yml) file into the root of your repo:

```bash
cp dev-lib/sample-config/.travis.yml .
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

Set `DEFAULT_BASE_BRANCH` to be whatever your default branch is in GitHub; this is use when doing diff-checks on changes in a branch build on Travis CI. The `PATH_INCLUDES` is especially useful when the dev-lib is used in the context of an entire site, so you can target just the themes and plugins that you're responsible for. For *excludes*, you can specify a `PHPCS_IGNORE` var and override the `.jshintignore`; there is a `PATH_EXCLUDES_PATTERN` as well.

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
