'use strict';

Object.defineProperty(exports, "__esModule", {
	value: true
});
exports.getTasks = undefined;

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpUtil = require('gulp-util');

var _gulpUtil2 = _interopRequireDefault(_gulpUtil);

var _requireDir = require('require-dir');

var _requireDir2 = _interopRequireDefault(_requireDir);

var _getConfig = require('./get-config');

var _sortTasks = require('./sort-tasks');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var getTasks = exports.getTasks = function getTasks() {
	var tasksList = void 0,
	    gulpTasks = void 0;

	// Load all Gulp tasks from `tasks` dir.
	(0, _requireDir2.default)('../tasks');

	// Filter the list to only contain existing Gulp tasks.
	tasksList = Object.keys(_getConfig.tasks).filter(function (task) {
		if (undefined === _gulp2.default.task(task)) {
			_gulpUtil2.default.log('Task \'' + _gulpUtil2.default.colors.red(task) + '\' is not defined, ignoring!');
			return false;
		}

		return true;
	});

	// Sort tasks into `before`, `after` and `tasks` lists.
	tasksList = (0, _sortTasks.sortTasks)(tasksList, ['js-lint']);
	gulpTasks = [];

	if (0 < tasksList.before.length) {
		gulpTasks.push(_gulp2.default.parallel(tasksList.before));
	}
	if (0 < tasksList.tasks.length) {
		gulpTasks.push(_gulp2.default.parallel(tasksList.tasks));
	}
	if (0 < tasksList.after.length) {
		gulpTasks.push(_gulp2.default.parallel(tasksList.after));
	}

	return gulpTasks;
};