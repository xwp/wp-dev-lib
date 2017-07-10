import gulp from 'gulp';
import { tasks } from '../utils/get-config';
import del from 'del';

if ( undefined !== tasks.clean ) {
	gulp.task( 'clean', done => {
		del( tasks.clean ).then( () => done() );
	} );
}
