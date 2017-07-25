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