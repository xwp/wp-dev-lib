import gulp from 'gulp';
import { tasks } from '../utils/get-config';
import watch from 'gulp-watch';
import { join } from 'path';
import _without from 'lodash/without';

if ( undefined !== tasks.watch && undefined !== tasks.watch.tasks ) {
	gulp.task( 'watch', () => {

		// Omit some tasks, e.g. `js` is already watched by Watchify.
		const filteredTasks = _without( tasks.watch.tasks, 'js', 'clean' );

		filteredTasks.forEach( taskSlug => {
			const task = tasks[ taskSlug ];
			let source;

			if ( undefined !== task.src && undefined !== task.glob ) {
				source = join( task.src, task.glob );
			} else if ( undefined !== task.src ) {
				source = task.src;
			} else {
				return;
			}

			watch( source, () => gulp.start( taskSlug ) );
		} );
	} );
}
