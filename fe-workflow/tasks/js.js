import { tasks, isDev, browserslist } from '../utils/get-config';
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

if ( undefined !== tasks.js ) {
	const babelifyOptions = {
		presets: [ [ 'env', {
			targets: {
				browsers: browserslist
			}
		} ] ]
	};

	gulp.task( 'js', [ 'js-lint' ], () => {
		const options = {
			paths: tasks.js.includePaths
		};

		let devBundler, prodBundler, jsTasks, jsTasksStream;

		devBundler = function( task ) {
			const opt    = Object.assign( { entries: task.entries, debug: true }, watchify.args, options ),
				  w      = watchify( browserify( opt ).transform( babelify, babelifyOptions ) ),
				  bundle = function() {
					  return w.bundle()
						  .on( 'error', ( error ) => {
							  gutil.log( error.codeFrame + '\n' + gutil.colors.red( error.toString() ) );
						  } )
						  .pipe( plumber() )
						  .pipe( source( task.bundle ) )
						  .pipe( buffer() )
						  .pipe( sourcemaps.init( { loadMaps: true } ) )
						  .pipe( sourcemaps.write( '' ) )
						  .pipe( gulp.dest( task.dest ) );
				  };

			w.on( 'update', bundle );
			w.on( 'log', gutil.log );

			return bundle();
		};

		prodBundler = function( task ) {
			const opt = Object.assign( { entries: task.entries, debug: false }, options );

			return browserify( opt )
				.transform( babelify, babelifyOptions )
				.bundle()
				.pipe( plumber() )
				.pipe( source( task.bundle ) )
				.pipe( buffer() )
				.pipe( uglify() )
				.pipe( gulp.dest( task.dest ) );
		};

		jsTasks = Array.isArray( tasks.js ) ? tasks.js : [ tasks.js ];
		jsTasksStream = jsTasks.map( isDev ? devBundler : prodBundler );

		return es.merge.apply( null, jsTasksStream );
	} );
}
