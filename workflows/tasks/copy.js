import gulp from 'gulp';
import gutil from 'gulp-util';
import { tasks, isDev } from '../utils/get-config';
import cache from 'gulp-cached';
import { join } from 'path';
import gulpIf from 'gulp-if';

if ( undefined !== tasks.copy ) {
	gulp.task( 'copy', () => {
		if ( undefined === tasks.copy.glob || undefined === tasks.copy.src || undefined === tasks.copy.dest ) {
			gutil.log( `Missing path in '${ gutil.colors.cyan( 'copy' ) }' task, aborting!` );
			return null;
		}

		return gulp
			.src( join( tasks.copy.src, tasks.copy.glob ) )
			.pipe( gulpIf( isDev, cache( 'copy-task-cache', { optimizeMemory: true } ) ) )
			.pipe( gulp.dest( tasks.copy.dest ) );
	} );
}
