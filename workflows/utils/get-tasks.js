import gulp from 'gulp';
import gutil from 'gulp-util';
import requireDir from 'require-dir';
import { tasks } from './get-config';
import { sortTasks } from './sort-tasks';

export const getTasks = function() {
	let tasksList, gulpTasks;

	// Load all Gulp tasks from `tasks` dir.
	requireDir( '../tasks' );

	// Filter the list to only contain existing Gulp tasks.
	tasksList = Object.keys( tasks ).filter( task => {
		if ( undefined === gulp.task( task ) ) {
			gutil.log( `Task '${ gutil.colors.red( task ) }' is not defined, ignoring!` );
			return false;
		}

		return true;
	} );

	// Sort tasks into `before`, `after` and `tasks` lists.
	tasksList = sortTasks( tasksList );
	gulpTasks = [];

	if ( 0 < tasksList.before.length ) {
		gulpTasks.push( gulp.parallel( tasksList.before ) );
	}
	if ( 0 < tasksList.tasks.length ) {
		gulpTasks.push( gulp.parallel( tasksList.tasks ) );
	}
	if ( 0 < tasksList.after.length ) {
		gulpTasks.push( gulp.parallel( tasksList.after ) );
	}

	return gulpTasks;
};
