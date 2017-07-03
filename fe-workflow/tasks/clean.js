import gulp from 'gulp';
import gutil from 'gulp-util';
import { paths } from '../utils/get-package-data';
import del from 'del';

gulp.task( 'clean', done => {
	if ( undefined === paths.clean ) {
		gutil.log( `Missing path in '${ gutil.colors.cyan( 'clean' ) }' task, aborting!` );
		done();
		return;
	}

	del( paths.clean ).then( () => done() );
} );
