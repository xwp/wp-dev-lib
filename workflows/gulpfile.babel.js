import { env, workflow, tasks } from './utils/get-config';
import requireDir from 'require-dir';
import gulp from 'gulp';
import gutil from 'gulp-util';
import runSequence from 'run-sequence';
import _without from 'lodash/without';

// Load all Gulp tasks from `tasks` dir.
requireDir( 'tasks' );

// To add a new task, simply create a new task file in `tasks` folder.
gulp.task( 'default', done => {
	if ( undefined === workflow ) {
		gutil.log( gutil.colors.red( `No workflow provided, aborting!` ) );
		return;
	}
	gutil.log( `Using '${ gutil.colors.yellow( workflow ) }' workflow...` );

	if ( undefined !== env ) {
		gutil.log( `Using '${ gutil.colors.yellow( env ) }' environment...` );
	}

	let tasksList = _without( Object.keys( tasks ), 'js-lint', 'cwd' );
	tasksList = tasksList.filter( task => {
		if ( undefined === gulp.tasks[ task ] ) {
			gutil.log( `Task '${ gutil.colors.red( task ) }' is not defined, ignoring!` );
			return false;
		}
		return true;
	} );

	if ( 0 === tasksList.length ) {
		gutil.log( `No tasks provided for workflow '${ gutil.colors.yellow( workflow ) }', aborting!` );
		return;
	}

	runSequence( ...tasksList, done );
} );
