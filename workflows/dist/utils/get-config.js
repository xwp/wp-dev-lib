'use strict';

Object.defineProperty(exports, "__esModule", {
	value: true
});
exports.browserslist = exports.workflow = exports.isProd = exports.isTest = exports.isDev = exports.cwd = exports.env = exports.tasks = exports.json = undefined;

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _yargs = require('yargs');

var _yargs2 = _interopRequireDefault(_yargs);

var _path = require('path');

var _gulpUtil = require('gulp-util');

var _gulpUtil2 = _interopRequireDefault(_gulpUtil);

var _defaultsDeep2 = require('lodash/defaultsDeep');

var _defaultsDeep3 = _interopRequireDefault(_defaultsDeep2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var json = JSON.parse(_fs2.default.readFileSync('./package.json')),
    env = _yargs2.default.argv.env,
    workflow = _yargs2.default.argv.workflow,
    browserslist = json.browserslist;

var tasks = [],
    cwd = '',
    schema = '',
    isTest = false,
    isProd = false,
    isDev = false;

switch (env) {
	case 'test':
		exports.isTest = isTest = true;
		break;
	case 'prod':
	case 'production':
		exports.isProd = isProd = true;
		break;
	default:
		exports.isDev = isDev = true;
}

if (undefined !== workflow && undefined !== json.workflows[workflow]) {
	exports.tasks = tasks = json.workflows[workflow];
}
if (undefined !== tasks.cwd) {
	exports.cwd = cwd = tasks.cwd;
	delete tasks.cwd;
}

function getSchema(slug) {
	var file = (0, _path.resolve)(__dirname, '../schemas/' + slug + '.json');

	if (!_fs2.default.existsSync(file)) {
		_gulpUtil2.default.log(_gulpUtil2.default.colors.yellow('Schema \'' + slug + '\' not found, ignoring...'));
		return {};
	}

	return JSON.parse(_fs2.default.readFileSync(file));
}
if (undefined !== tasks.schema) {
	schema = getSchema(tasks.schema);
	delete tasks.schema;
	exports.tasks = tasks = (0, _defaultsDeep3.default)(tasks, schema);
}

exports.json = json;
exports.tasks = tasks;
exports.env = env;
exports.cwd = cwd;
exports.isDev = isDev;
exports.isTest = isTest;
exports.isProd = isProd;
exports.workflow = workflow;
exports.browserslist = browserslist;