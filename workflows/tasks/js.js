import { tasks, isProd, isDev, browserslist, cwd } from '../utils/get-config';
import gulp from 'gulp';
import mergeStream from 'merge-stream';
import { join, resolve } from 'path';
import webpack from 'webpack';
import webpackStream from 'webpack-stream';
const ProgressBarPlugin = require('progress-bar-webpack-plugin')
const {removeEmpty} = require('webpack-config-utils')

if ( undefined !== tasks.js ) {
	function fn() {
		let jsTasks, jsTasksStream, babelifyOptions;
		const paths = tasks.js;

		babelifyOptions = {
			presets: [
				["env", {
					"targets": {
						browsers: browserslist
					}
				}]
			]
		}

		const webpackConfig = {
			context: resolve( cwd, paths.base ),
			entry: paths.entry,
			output: {
				filename: '[name].js',
				pathinfo: true == isDev,
			},
			devtool: isProd ? 'source-map': 'eval',
			module: {
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
		}

		const webpackJs = function( task ) {
			return gulp.src( resolve( cwd, paths.base ) )
				.pipe( webpackStream( webpackConfig, webpack ) )
				.pipe( gulp.dest( resolve( cwd, paths.dest ) ) );
		}

		jsTasks       = Array.isArray( tasks.js ) ? tasks.js : [ tasks.js ];
		jsTasksStream = jsTasks.map( webpackJs );

		return mergeStream( jsTasksStream );
	}

	fn.displayName = 'js-compile';

	if ( undefined !== tasks['js-lint'] ) {
		gulp.task( 'js', gulp.series( 'js-lint', fn ) );
	} else {
		gulp.task( 'js', fn );
	}
}
