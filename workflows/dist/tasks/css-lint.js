'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpCached = require('gulp-cached');

var _gulpCached2 = _interopRequireDefault(_gulpCached);

var _getConfig = require('../utils/get-config');

var _gulpIf = require('gulp-if');

var _gulpIf2 = _interopRequireDefault(_gulpIf);

var _gulpPostcss = require('gulp-postcss');

var _gulpPostcss2 = _interopRequireDefault(_gulpPostcss);

var _postcssReporter = require('postcss-reporter');

var _postcssReporter2 = _interopRequireDefault(_postcssReporter);

var _postcssScss = require('postcss-scss');

var _postcssScss2 = _interopRequireDefault(_postcssScss);

var _stylelint = require('stylelint');

var _stylelint2 = _interopRequireDefault(_stylelint);

var _TaskHelper = require('../utils/TaskHelper');

var _TaskHelper2 = _interopRequireDefault(_TaskHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var task = new _TaskHelper2.default({
	name: 'css-lint',
	requiredPaths: ['src'],
	config: _getConfig.tasks,
	configSlug: 'css'
});

if (undefined !== task.config) {
	_gulp2.default.task(task.name, function () {
		if (!task.isValid()) {
			return null;
		}

		return task.start().pipe((0, _gulpIf2.default)(_getConfig.isDev, (0, _gulpCached2.default)(task.cacheName))).pipe((0, _gulpPostcss2.default)([(0, _stylelint2.default)(), (0, _postcssReporter2.default)({ clearAllMessages: true })], { syntax: _postcssScss2.default }));
	});
}