'use strict';

var _sortTasks = require('./sort-tasks');

describe('sortTasks()', function () {
	test('returns before and main tasks', function () {
		expect((0, _sortTasks.sortTasks)(['clean', 'js', 'css'])).toEqual({
			before: ['clean'],
			tasks: ['js', 'css'],
			after: []
		});
	});

	test('returns before, after and main tasks', function () {
		expect((0, _sortTasks.sortTasks)(['watch', 'clean', 'js', 'css'])).toEqual({
			before: ['clean'],
			tasks: ['js', 'css'],
			after: ['watch']
		});
	});

	test('returns after and main tasks', function () {
		expect((0, _sortTasks.sortTasks)(['watch', 'js', 'css'])).toEqual({
			before: [],
			tasks: ['js', 'css'],
			after: ['watch']
		});
	});

	test('returns after tasks only', function () {
		expect((0, _sortTasks.sortTasks)(['watch'])).toEqual({
			before: [],
			tasks: [],
			after: ['watch']
		});
	});

	test('returns main tasks only', function () {
		expect((0, _sortTasks.sortTasks)(['css'])).toEqual({
			before: [],
			tasks: ['css'],
			after: []
		});
	});

	test('returns before tasks only', function () {
		expect((0, _sortTasks.sortTasks)(['clean'])).toEqual({
			before: ['clean'],
			tasks: [],
			after: []
		});
	});

	test('specified tasks are ignored', function () {
		expect((0, _sortTasks.sortTasks)(['watch', 'clean', 'js', 'css'], ['css'])).toEqual({
			before: ['clean'],
			tasks: ['js'],
			after: ['watch']
		});
	});

	test('specified tasks are ignored', function () {
		expect((0, _sortTasks.sortTasks)(['watch', 'clean', 'js', 'css'], ['clean'])).toEqual({
			before: [],
			tasks: ['js', 'css'],
			after: ['watch']
		});
	});

	test('specified tasks are ignored', function () {
		expect((0, _sortTasks.sortTasks)(['watch', 'clean', 'js', 'css'], ['watch'])).toEqual({
			before: ['clean'],
			tasks: ['js', 'css'],
			after: []
		});
	});
}); /* eslint-env jest */