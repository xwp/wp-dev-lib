wp-dev-lib
==========

**Common tools to facilitate the development and testing of WordPress themes and plugins**

## Installation

It is intended that this repo be included in plugin repo via git-submodule in a `dev-lib/` directory. (Previously it was recommended to be a git-subtree, but this has changed now that the `.travis.yml` is now lightweight enough to not require a symlink.)

To **add** it to your repo, do:

```bash
remote_branch=vip-themes # temporary
git submodule add -b $remote_branch git@github.com:xwpco/wp-plugin-dev-lib.git dev-lib
```

To **update** the library with the latest changes:

```bash
git submodule update --remote dev-lib
git add dev-lib
git commit -m "Update dev-lib"
```

## Travis

Copy the [`.travis.yml`](.travis.yml) file into the root of your repo:

```bash
cp dev-lib/.travis.yml .
```

Note that the builk of the logic in this config file is now moved to [`travis.before_script.sh`](travis.before_script.sh), [`travis.script.sh`](travis.script.sh), and [`travis.after_script.sh`](travis.after_script.sh), so there is minimal chance for the `.travis.yml` to diverge from upstream.

Edit the `.travis.yml` to change the target PHP version(s) and WordPress version(s) you need to test for and also whether you need to test on multisite or not:

```yml
php:
    - 5.4
    - 5.5

env:
    - WP_VERSION=latest WP_MULTISITE=0
    - WP_VERSION=latest WP_MULTISITE=1
    - WP_VERSION=4.0 WP_MULTISITE=0
    - WP_VERSION=4.0 WP_MULTISITE=1
```

Having more variations here is good for open source plugins, which are free for Travis. However, if you are using Travis CI with a private repo you probably want to limit the jobs necessary to complete a build. So if your production environment is running PHP 5.5, is on the latest stable version of WordPress, and is not multisite, then your `.travis.yml` could just be:

```yml
php:
    - 5.5

env:
    - WP_VERSION=4.0 WP_MULTISITE=0
```

This will greatly speed up the time build time, giving you quicker feedback on your Pull Request status, and prevent your Travis build queue from getting too backlogged.

## Symlinks

Next, after configuring your `.travis.yml`, symlink the [`.jshintrc`](.jshint), [`.jshintignore`](.jshintignore), and (especially optionally) [`phpcs.ruleset.xml`](phpcs.ruleset.xml):

```bash
ln -s bin/.jshintrc . && git add .jshintrc
ln -s bin/.jshintignore . && git add .jshintignore
ln -s bin/phpcs.ruleset.xml . && git add phpcs.ruleset.xml # Note: Probably better to supply the WPCS_STANDARD env var per below
```

## Pre-commit Hook

Symlink to [`pre-commit`](pre-commit) from your project's `.git/hooks/pre-commit`:

```bash
cd .git/hooks && ln -s ../../dev-lib/pre-commit . && cd -
```

## Environment Variables

You may customize the behavior of the `.travis.yml` and `pre-commit` hook by
specifying a `.ci-env.sh` in the root of the repo, for example:

```bash
export PHPCS_GITHUB_SRC=xwpco/PHP_CodeSniffer
export PHPCS_GIT_TREE=phpcs-patch
export PHPCS_IGNORE='tests/*,includes/vendor/*' # See also PATH_INCLUDES below
export WPCS_GIT_TREE=develop
export WPCS_STANDARD=WordPress-Extra
export DISALLOW_EXECUTE_BIT=1
export YUI_COMPRESSOR_CHECK=1
export PATH_INCLUDES="docroot/wp-content/plugins/acme-* docroot/wp-content/themes/acme-*"
```

The last one here `PATH_INCLUDES` is especially useful when the dev-lib is used in the context of an entire site, so you can target just the themes and plugins that you're responsible for. For *excludes*, you can specify a `PHPCS_IGNORE` var and override the `.jshintignore`, though it would be better to have a `PATH_EXCLUDES` as well.

It is better to add these statements to this file instead of to the `before_script` section of your `.travis.yml` because the `.ci-env.sh` is also `source`ed by the `pre-commit` hook.

## Plugin Helpers

The library includes a WordPress README [parser](class-wordpress-readme-parser.php) and [converter](generate-markdown-readme) to Markdown, so you don't have to manually keep your `readme.txt` on WordPress.org in sync with the `readme.md` you have on GitHub. The converter will also automatically recognize the presence of projects with Travis CI and include the status image in the markdown. Screenshots and banner images for WordPress.org are also automatically incorporated into the `readme.md`.

What is also included in this repo is an [`svn-push`](svn-push) to push commits from a GitHub repo to the WordPress.org SVN repo for the plugin. The `/assets/` directory in the root of the project will get automatically moved one directory above in the SVN repo (alongside `trunk`, `branches`, and `tags`). To use, include an `svn-url` file in the root of your repo and let this file contains he full root URL to the WordPress.org repo for plugin (don't include `trunk`).

The utilities in this project were first developed to facilitate development of [X-Team](http://x-team.com/wordpress/)'s [plugins](http://profiles.wordpress.org/x-team/).
