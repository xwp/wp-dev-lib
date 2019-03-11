# Contribute

All contributions, suggestions and ideas are welcome!

## Project Overview

- All features and fixes are added by creating a pull request with the suggested changes (see the instructions below). This will also run [a few automated checks](https://github.com/xwp/wp-dev-lib/blob/master/.travis.yml) for the changeset [on Travis CI](https://travis-ci.org/xwp/wp-dev-lib).

- We use [semantic versioning](https://semver.org) and [Git tags](https://github.com/xwp/wp-dev-lib/releases) for creating releases. All code merged to `master` branch is included in the next release so ensure that minor bug fixes are not combined with breaking changes.

- We support multiple installation methods -- npm, Composer and Git submodules. All changes should take that into account.

- Most of the functionality relies [on Bash scripts](https://github.com/xwp/wp-dev-lib/tree/master/scripts) which can not run on Windows machines. For all new functionality we should try to use PHP or JS scripts that are supported on all operating systems.

## Report Issues and Suggestions

- Review [the existing issues](https://github.com/xwp/wp-dev-lib/issues) for similar issues or suggestions.
- Open [a new issue](https://github.com/xwp/wp-dev-lib/issues/new) on GitHub.

## Submit a Pull Request

See the [GitHub documentation for creating pull requests](https://help.github.com/en/articles/creating-a-pull-request).

- Clone this repository.
- Create a new branch based from `master`.
- Open a pull requests against the `master` branch of [the upstream repository](https://github.com/xwp/wp-dev-lib).
