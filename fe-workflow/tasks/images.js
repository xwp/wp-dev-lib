import gulp from 'gulp';
import gutil from 'gulp-util';
import { tasks, isDev } from '../utils/get-config';
import cache from 'gulp-cached';
import imagemin from 'gulp-imagemin';
import { join } from 'path';
import gulpIf from 'gulp-if';
//import { bs } from './browser-sync';

if ( undefined !== tasks.images ) {
	gulp.task( 'images', () => {
		if ( undefined === tasks.images.glob || undefined === tasks.images.src || undefined === tasks.images.dest ) {
			gutil.log( `Missing path in '${ gutil.colors.cyan( 'images' ) }' task, aborting!` );
			return null;
		}

		return gulp
			.src( join( tasks.images.src, tasks.images.glob ) )
			.pipe( gulpIf( isDev, cache( 'images-task-cache', { optimizeMemory: true } ) ) )
			.pipe( imagemin() )
			.pipe( gulp.dest( tasks.images.dest ) );
		//.pipe( gulpIf( isDev, bs.stream() ) );
	} );
}
