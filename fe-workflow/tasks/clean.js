import gulp from 'gulp';
import gutil from 'gulp-util';
import { tasks } from '../utils/get-package-data';
import del from 'del';

gulp.task( 'clean', done => {
	if ( undefined === tasks.clean ) {
		gutil.log( `Missing path in '${ gutil.colors.cyan( 'clean' ) }' task, aborting!` );
		done();
		return;
	}

	del( tasks.clean ).then( () => done() );
} );
