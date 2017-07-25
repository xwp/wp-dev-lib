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
'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _getConfig = require('../utils/get-config');

var _del = require('del');

var _del2 = _interopRequireDefault(_del);

var _TaskHelper = require('../utils/TaskHelper');

var _TaskHelper2 = _interopRequireDefault(_TaskHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var task = new _TaskHelper2.default({
	name: 'clean',
	requiredPaths: ['src'],
	config: _getConfig.tasks
});

_gulp2.default.task(task.name, function (done) {
	if (task.isValid()) {
		(0, _del2.default)(task.src).then(function () {
			return done();
		});
	}
});
'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpIf = require('gulp-if');

var _gulpIf2 = _interopRequireDefault(_gulpIf);

var _gulpCached = require('gulp-cached');

var _gulpCached2 = _interopRequireDefault(_gulpCached);

var _getConfig = require('../utils/get-config');

var _TaskHelper = require('../utils/TaskHelper');

var _TaskHelper2 = _interopRequireDefault(_TaskHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var task = new _TaskHelper2.default({
	name: 'copy',
	requiredPaths: ['src', 'dest'],
	config: _getConfig.tasks
});

_gulp2.default.task(task.name, function () {
	if (!task.isValid()) {
		return null;
	}

	return task.start().pipe((0, _gulpIf2.default)(_getConfig.isDev, (0, _gulpCached2.default)(task.cacheName, { optimizeMemory: false }))).pipe(task.end());
});
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
'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpCached = require('gulp-cached');

var _gulpCached2 = _interopRequireDefault(_gulpCached);

var _gulpProgeny = require('gulp-progeny');

var _gulpProgeny2 = _interopRequireDefault(_gulpProgeny);

var _getConfig = require('../utils/get-config');

var _gulpSass = require('gulp-sass');

var _gulpSass2 = _interopRequireDefault(_gulpSass);

var _gulpSourcemaps = require('gulp-sourcemaps');

var _gulpSourcemaps2 = _interopRequireDefault(_gulpSourcemaps);

var _gulpIf = require('gulp-if');

var _gulpIf2 = _interopRequireDefault(_gulpIf);

var _gulpPostcss = require('gulp-postcss');

var _gulpPostcss2 = _interopRequireDefault(_gulpPostcss);

var _postcssCssnext = require('postcss-cssnext');

var _postcssCssnext2 = _interopRequireDefault(_postcssCssnext);

var _postcssPxtorem = require('postcss-pxtorem');

var _postcssPxtorem2 = _interopRequireDefault(_postcssPxtorem);

var _autoprefixer = require('autoprefixer');

var _autoprefixer2 = _interopRequireDefault(_autoprefixer);

var _postcssAssets = require('postcss-assets');

var _postcssAssets2 = _interopRequireDefault(_postcssAssets);

var _TaskHelper = require('../utils/TaskHelper');

var _TaskHelper2 = _interopRequireDefault(_TaskHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var task = new _TaskHelper2.default({
	name: 'css',
	requiredPaths: ['src', 'dest'],
	config: _getConfig.tasks
});

if (undefined !== task.config) {
	var fn = function fn() {
		if (!task.isValid()) {
			return null;
		}

		return task.start()

		// Caching and incremental building (progeny) in Gulp.
		.pipe((0, _gulpIf2.default)(_getConfig.isDev, (0, _gulpCached2.default)(task.cacheName))).pipe((0, _gulpIf2.default)(_getConfig.isDev, (0, _gulpProgeny2.default)()))

		// Actual SASS compilation.
		.pipe((0, _gulpIf2.default)(_getConfig.isDev, _gulpSourcemaps2.default.init())).pipe((0, _gulpSass2.default)({
			includePaths: undefined !== task.config.includePaths ? task.config.includePaths : [],
			outputStyle: _getConfig.isDev ? 'expanded' : 'compressed'
		}).on('error', _gulpSass2.default.logError)).pipe((0, _gulpPostcss2.default)(getProcessors(task.config.postcssProcessors))).pipe((0, _gulpIf2.default)(_getConfig.isDev, _gulpSourcemaps2.default.write(''))).pipe(task.end());
	};

	fn.displayName = 'css-compile';

	if (undefined !== task.config.enableLinter && true === task.config.enableLinter) {
		_gulp2.default.task('css', _gulp2.default.series('css-lint', fn));
	} else {
		_gulp2.default.task('css', fn);
	}
}

function getProcessors(settings) {
	var processors = [],
	    defaults = void 0,
	    s = void 0;

	defaults = {
		cssnext: {
			warnForDuplicates: false
		},
		autoprefixer: {},
		pxtorem: {
			rootValue: 16,
			unitPrecision: 5,
			propList: ['*'],
			selectorBlackList: [],
			replace: true,
			mediaQuery: true,
			minPixelValue: 2
		},
		assets: {
			relative: true
		}
	};

	if (false !== settings.cssnext) {
		s = true === settings.cssnext ? {} : settings.cssnext;
		processors.push((0, _postcssCssnext2.default)(Object.assign(defaults.cssnext, s)));
	}

	if (false !== settings.autoprefixer) {
		s = true === settings.autoprefixer ? {} : settings.autoprefixer;
		processors.push((0, _autoprefixer2.default)(Object.assign(defaults.autoprefixer, s)));
	}

	if (false !== settings.pxtorem) {
		s = true === settings.pxtorem ? {} : settings.pxtorem;
		processors.push((0, _postcssPxtorem2.default)(Object.assign(defaults.pxtorem, s)));
	}

	if (false !== settings.assets) {
		s = true === settings.assets ? {} : settings.assets;
		processors.push((0, _postcssAssets2.default)(Object.assign(defaults.assets, s)));
	}

	return processors;
}
'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpIf = require('gulp-if');

var _gulpIf2 = _interopRequireDefault(_gulpIf);

var _gulpCached = require('gulp-cached');

var _gulpCached2 = _interopRequireDefault(_gulpCached);

var _gulpImagemin = require('gulp-imagemin');

var _gulpImagemin2 = _interopRequireDefault(_gulpImagemin);

var _getConfig = require('../utils/get-config');

var _TaskHelper = require('../utils/TaskHelper');

var _TaskHelper2 = _interopRequireDefault(_TaskHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var task = new _TaskHelper2.default({
	name: 'images',
	requiredPaths: ['src', 'dest'],
	config: _getConfig.tasks
});

_gulp2.default.task(task.name, function () {
	if (!task.isValid()) {
		return null;
	}

	return task.start().pipe((0, _gulpIf2.default)(_getConfig.isDev, (0, _gulpCached2.default)(task.cacheName, { optimizeMemory: false }))).pipe((0, _gulpImagemin2.default)()).pipe(task.end());
});
'use strict';

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpCached = require('gulp-cached');

var _gulpCached2 = _interopRequireDefault(_gulpCached);

var _getConfig = require('../utils/get-config');

var _gulpEslint = require('gulp-eslint');

var _gulpEslint2 = _interopRequireDefault(_gulpEslint);

var _gulpIf = require('gulp-if');

var _gulpIf2 = _interopRequireDefault(_gulpIf);

var _TaskHelper = require('../utils/TaskHelper');

var _TaskHelper2 = _interopRequireDefault(_TaskHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var task = new _TaskHelper2.default({
	name: 'js-lint',
	requiredPaths: ['src'],
	config: _getConfig.tasks
});

if (undefined !== task.config) {
	_gulp2.default.task(task.name, function () {
		if (!task.isValid()) {
			return null;
		}

		return task.start().pipe((0, _gulpIf2.default)(_getConfig.isDev, (0, _gulpCached2.default)(task.cacheName))).pipe((0, _gulpEslint2.default)()).pipe((0, _gulpIf2.default)(_getConfig.isProd, _gulpEslint2.default.format())).pipe((0, _gulpIf2.default)(_getConfig.isProd, _gulpEslint2.default.failAfterError()));
	});
}
'use strict';

var _getConfig = require('../utils/get-config');

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _path = require('path');

var _webpack = require('webpack');

var _webpack2 = _interopRequireDefault(_webpack);

var _webpackStream = require('webpack-stream');

var _webpackStream2 = _interopRequireDefault(_webpackStream);

var _progressBarWebpackPlugin = require('progress-bar-webpack-plugin');

var _progressBarWebpackPlugin2 = _interopRequireDefault(_progressBarWebpackPlugin);

var _webpackConfigUtils = require('webpack-config-utils');

var _gulpPlumber = require('gulp-plumber');

var _gulpPlumber2 = _interopRequireDefault(_gulpPlumber);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

if (undefined !== _getConfig.tasks.js) {
	var fn = function fn() {
		var babelifyOptions = void 0,
		    webpackConfig = void 0,
		    esLintOptions = {};
		var paths = _getConfig.tasks.js;

		babelifyOptions = {
			presets: [['env', {
				targets: {
					browsers: _getConfig.browserslist
				}
			}]]
		};

		// Avoid linting for the test environment
		if (_getConfig.isDev || _getConfig.isProd) {
			esLintOptions = {
				test: /\.js$/,
				loader: 'eslint-loader',
				exclude: /(node_modules)/
			};
		}

		webpackConfig = {
			context: (0, _path.resolve)(_getConfig.cwd, paths.base),
			entry: paths.entry,
			output: {
				filename: '[name].js',
				pathinfo: _getConfig.isDev
			},
			devtool: _getConfig.isProd ? 'source-map' : 'eval',
			module: {
				rules: [esLintOptions],
				loaders: [{
					test: /\.js$/,
					loader: 'babel-loader',
					options: babelifyOptions,
					exclude: /node_modules/
				}]
			},
			plugins: (0, _webpackConfigUtils.removeEmpty)([new _progressBarWebpackPlugin2.default(), _getConfig.isProd ? new _webpack2.default.optimize.UglifyJsPlugin() : undefined]),
			watch: true,
			cache: true
		};

		return _gulp2.default.src((0, _path.resolve)(_getConfig.cwd, paths.base)).pipe((0, _gulpPlumber2.default)()).pipe((0, _webpackStream2.default)(webpackConfig, _webpack2.default)).pipe(_gulpPlumber2.default.stop()).pipe(_gulp2.default.dest((0, _path.resolve)(_getConfig.cwd, paths.dest)));
	};

	fn.displayName = 'js-compile';

	if (undefined !== _getConfig.tasks['js-lint']) {
		_gulp2.default.task('js', _gulp2.default.series('js-lint', fn));
	} else {
		_gulp2.default.task('js', fn);
	}
}
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
'use strict';

Object.defineProperty(exports, "__esModule", {
	value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _gulp = require('gulp');

var _gulp2 = _interopRequireDefault(_gulp);

var _gulpUtil = require('gulp-util');

var _gulpUtil2 = _interopRequireDefault(_gulpUtil);

var _path = require('path');

var _getConfig = require('./get-config');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var TaskHelper = function () {
	function TaskHelper(_ref) {
		var _ref$name = _ref.name,
		    name = _ref$name === undefined ? '' : _ref$name,
		    _ref$requiredPaths = _ref.requiredPaths,
		    requiredPaths = _ref$requiredPaths === undefined ? [] : _ref$requiredPaths,
		    _ref$config = _ref.config,
		    config = _ref$config === undefined ? null : _ref$config,
		    _ref$configSlug = _ref.configSlug,
		    configSlug = _ref$configSlug === undefined ? '' : _ref$configSlug;

		_classCallCheck(this, TaskHelper);

		if (null === config) {
			_gulpUtil2.default.log(_gulpUtil2.default.colors.red('The task template is missing a configuration.'));
			return;
		}

		this._name = name;
		this._requiredPaths = requiredPaths;
		this._config = config;
		this._configSlug = '' === configSlug ? name : configSlug;
	}

	_createClass(TaskHelper, [{
		key: 'isValid',
		value: function isValid() {
			if (!this.hasPathsDefined) {
				_gulpUtil2.default.log('Missing paths in \'' + _gulpUtil2.default.colors.red(this.name) + '\' task, aborting!');
				return false;
			}
			return true;
		}
	}, {
		key: 'start',
		value: function start() {
			return _gulp2.default.src(this.src, { base: this.base });
		}
	}, {
		key: 'end',
		value: function end() {
			return _gulp2.default.dest(this.dest, { cwd: _getConfig.cwd });
		}
	}, {
		key: 'config',
		get: function get() {
			return '' === this.configSlug ? this._config : this._config[this.configSlug];
		}
	}, {
		key: 'name',
		get: function get() {
			return this._name;
		}
	}, {
		key: 'configSlug',
		get: function get() {
			return this._configSlug;
		}
	}, {
		key: 'requiredPaths',
		get: function get() {
			return this._requiredPaths;
		}
	}, {
		key: 'hasPathsDefined',
		get: function get() {
			var _this = this;

			return this.requiredPaths.every(function (path) {
				return undefined !== _this.config[path];
			});
		}
	}, {
		key: 'src',
		get: function get() {
			var srcList = Array.isArray(this.config.src) ? this.config.src : [this.config.src],
			    src = srcList.map(function (path) {
				return (0, _path.join)(_getConfig.cwd, path);
			});

			return src;
		}
	}, {
		key: 'entries',
		get: function get() {
			var entriesList = Array.isArray(this.config.entries) ? this.config.entries : [this.config.entries],
			    entries = entriesList.map(function (path) {
				return (0, _path.join)(_getConfig.cwd, path);
			});

			return entries;
		}
	}, {
		key: 'base',
		get: function get() {
			return undefined === this.config.base ? '' : (0, _path.join)(_getConfig.cwd, this.config.base);
		}
	}, {
		key: 'dest',
		get: function get() {
			return this.config.dest;
		}
	}, {
		key: 'cacheName',
		get: function get() {
			return this.name + '-task-cache';
		}
	}]);

	return TaskHelper;
}();

exports.default = TaskHelper;
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
