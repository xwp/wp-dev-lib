'use strict';

Object.defineProperty(exports, "__esModule", {
	value: true
});
/**
 * Split tasks into 3 categories: main tasks, before and after.
 *
 * @param {Array} allTasks Set of all tasks
 * @param {Array} ignoredTasks Tasks to ignore
 * @return {{before: Array, tasks: Array, after: Array}} Categorized tasks object
 */
var sortTasks = exports.sortTasks = function sortTasks(allTasks, ignoredTasks) {
	var tasks = allTasks,
	    before = [],
	    after = [];

	if (undefined !== ignoredTasks) {
		tasks = tasks.filter(function (task) {
			return !ignoredTasks.includes(task);
		});
	}

	if (tasks.includes('clean')) {
		before.push('clean');
		tasks = tasks.filter(function (task) {
			return 'clean' !== task;
		});
	}

	if (tasks.includes('watch')) {
		after.push('watch');
		tasks = tasks.filter(function (task) {
			return 'watch' !== task;
		});
	}

	return { before: before, tasks: tasks, after: after };
};