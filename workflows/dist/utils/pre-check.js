'use strict';

Object.defineProperty(exports, "__esModule", {
	value: true
});
exports.preCheck = undefined;

var _gulpUtil = require('gulp-util');

var _gulpUtil2 = _interopRequireDefault(_gulpUtil);

var _validateNodeVersion = require('validate-node-version');

var _validateNodeVersion2 = _interopRequireDefault(_validateNodeVersion);

var _getConfig = require('./get-config');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var preCheck = exports.preCheck = function preCheck() {
	var nodeTest = (0, _validateNodeVersion2.default)(),
	    exitCode = 1;

	if (!nodeTest.satisfies) {
		_gulpUtil2.default.log(_gulpUtil2.default.colors.red(nodeTest.message));
		process.exit(exitCode);
	}

	if (undefined === _getConfig.workflow) {
		_gulpUtil2.default.log(_gulpUtil2.default.colors.red('No workflow provided, aborting!'));
		process.exit(exitCode);
	} else {
		_gulpUtil2.default.log('Using \'' + _gulpUtil2.default.colors.yellow(_getConfig.workflow) + '\' workflow...');
	}

	if (undefined !== _getConfig.env) {
		_gulpUtil2.default.log('Using \'' + _gulpUtil2.default.colors.yellow(_getConfig.env) + '\' environment...');
	}
};