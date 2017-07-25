'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _getConfig = require('../utils/get-config');

var _gulpWatch = require('gulp-watch');

var _gulpWatch2 = _interopRequireDefault(_gulpWatch);

var _path = require('path');

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

if (undefined !== _getConfig.tasks.watch && undefined !== _getConfig.tasks.watch.tasks) {
	_gulp2.default.task('watch', function () {

		// Omit some tasks, e.g. `js` is already watched by Webpack.
		var filteredTasks = (0, _without3.default)(_getConfig.tasks.watch.tasks, 'js', 'js-lint', 'clean');

		filteredTasks.forEach(function (taskSlug) {
			var task = _getConfig.tasks[taskSlug];

			if (undefined === task.src) {
				return;
			}

			(0, _gulpWatch2.default)((0, _path.join)(_getConfig.cwd, task.src), function () {
				return _gulp2.default.start(taskSlug);
			});
		});
	});
}