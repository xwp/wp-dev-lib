import { tasks, isProd, isDev, browserslist, cwd } from '../utils/get-config';
import gulp from 'gulp';
import { resolve } from 'path';
import webpack from 'webpack';
import webpackStream from 'webpack-stream';
import ProgressBarPlugin from 'progress-bar-webpack-plugin';
import { removeEmpty } from 'webpack-config-utils';
import plumber from 'gulp-plumber';

if ( undefined !== tasks.js ) {
	let fn = function() {
		let babelifyOptions, webpackConfig, esLintOptions = {};
		const paths = tasks.js;

		babelifyOptions = {
			presets: [
				[ 'env', {
					targets: {
						browsers: browserslist
					}
				} ]
			]
		};

		// Avoid linting for the test environment
		if ( isDev || isProd ) {
			esLintOptions = {
				test: /\.js$/,
				loader: 'eslint-loader',
				exclude: /(node_modules)/
			};
		}

		webpackConfig = {
			context: resolve( cwd, paths.base ),
			entry: paths.entry,
			output: {
				filename: '[name].js',
				pathinfo: isDev,
			},
			devtool: isProd ? 'source-map': 'eval',
			module: {
				rules: [
					esLintOptions
				],
				loaders: [
					{
						test: /\.js$/,
						loader: 'babel-loader',
						options: babelifyOptions,
						exclude: /node_modules/
					},
				],
			},
			plugins: removeEmpty([
				new ProgressBarPlugin(),
				isProd ? new webpack.optimize.UglifyJsPlugin() : undefined
			]),
			watch: true,
			cache: true,
		};

		return gulp.src( resolve( cwd, paths.base ) )
			.pipe( plumber() )
			.pipe( webpackStream( webpackConfig, webpack ) )
			.pipe( plumber.stop() )
			.pipe( gulp.dest( resolve( cwd, paths.dest ) ) );
	};

	fn.displayName = 'js-compile';

	if ( undefined !== tasks['js-lint'] ) {
		gulp.task( 'js', gulp.series( 'js-lint', fn ) );
	} else {
		gulp.task( 'js', fn );
	}
}
