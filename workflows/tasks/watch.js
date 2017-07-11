import gulp from 'gulp';
import { tasks, cwd } from '../utils/get-config';
import watch from 'gulp-watch';
import { join } from 'path';
import _without from 'lodash/without';

if ( undefined !== tasks.watch && undefined !== tasks.watch.tasks ) {
	gulp.task( 'watch', () => {

		// Omit some tasks, e.g. `js` is already watched by Watchify.
		const filteredTasks = _without( tasks.watch.tasks, 'js', 'js-lint', 'clean' );

		filteredTasks.forEach( taskSlug => {
			const task = tasks[ taskSlug ];
			let source;

			if ( undefined !== task.src ) {
				source = join( cwd, task.src );
			} else {
				return;
			}

			watch( source, () => gulp.start( taskSlug ) );
		} );
	} );
}
