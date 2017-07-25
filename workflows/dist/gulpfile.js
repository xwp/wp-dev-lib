'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _preCheck = require('./utils/pre-check');

var _getTasks = require('./utils/get-tasks');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Check Node version and workflow setup.
(0, _preCheck.preCheck)();

// Define default task.
_gulp2.default.task('default', _gulp2.default.series((0, _getTasks.getTasks)()));