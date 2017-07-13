import { tasks, isProd, browserslist, cwd } from '../utils/get-config';
import gulp from 'gulp';
import plumber from 'gulp-plumber';
import browserify from 'browserify';
import babelify from 'babelify';
import watchify from 'watchify';
import source from 'vinyl-source-stream';
import buffer from 'vinyl-buffer';
import sourcemaps from 'gulp-sourcemaps';
//import { bs } from './browser-sync';
import uglify from 'gulp-uglify';
import gutil from 'gulp-util';
import es from 'event-stream';
import { join } from 'path';

if ( undefined !== tasks.js ) {
	function fn() {
		let defaultBundler, prodBundler, jsTasks, jsTasksStream, addCwdToPaths, babelifyOptions;

		babelifyOptions = {
			presets: [ [ 'env', {
				targets: {
					browsers: browserslist
				}
			} ] ]
		};

		addCwdToPaths = function( paths ) {
			let path = Array.isArray( paths ) ? paths : [ paths ];
			path = path.filter( function(element) { return element != undefined } )
			return path.map( entry => join( cwd, entry ) );
		};

		defaultBundler = function( task ) {
			let options, watchifyTask, bundle;

			options = Object.assign( {
				entries: addCwdToPaths( task.entries ),
				paths:   addCwdToPaths( task.includePaths ),
				debug:   true
			}, watchify.args );

			watchifyTask = watchify( browserify( options ).transform( babelify, babelifyOptions ) );

			bundle = function() {
				return watchifyTask.bundle()
					.on( 'error', ( error ) => {
						gutil.log( error.codeFrame + '\n' + gutil.colors.red( error.toString() ) );
					} )
					.pipe( plumber() )
					.pipe( source( task.bundle ) )
					.pipe( buffer() )
					.pipe( sourcemaps.init( { loadMaps: true } ) )
					.pipe( sourcemaps.write( '' ) )
					.pipe( gulp.dest( task.dest, { cwd } ) );
			};

			watchifyTask.on( 'update', bundle );
			watchifyTask.on( 'log', gutil.log );

			return bundle();
		};

		prodBundler = function( task ) {
			const options = {
				entries: addCwdToPaths( task.entries ),
				paths:   addCwdToPaths( task.includePaths ),
				debug:   false
			};

			return browserify( options )
				.transform( babelify, babelifyOptions )
				.bundle()
				.pipe( plumber() )
				.pipe( source( task.bundle ) )
				.pipe( buffer() )
				.pipe( uglify() )
				.pipe( gulp.dest( task.dest, { cwd } ) );
		};

		jsTasks       = Array.isArray( tasks.js ) ? tasks.js : [ tasks.js ];
		jsTasksStream = jsTasks.map( isProd ? prodBundler : defaultBundler );

		return es.merge.apply( null, jsTasksStream );
	}

	fn.displayName = 'js-compile';

	if ( undefined !== tasks['js-lint'] ) {
		gulp.task( 'js', gulp.series( 'js-lint', fn ) );
	} else {
		gulp.task( 'js', fn );
	}
}
