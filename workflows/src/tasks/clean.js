import gulp from 'gulp';
import { tasks } from '../utils/get-config';
import del from 'del';
import TaskHelper from '../utils/TaskHelper';

const task = new TaskHelper( {
	name: 'clean',
	requiredPaths: ['src'],
	config: tasks
} );

gulp.task( task.name, done => {
	if ( task.isValid() ) {
		del( task.src ).then( () => done() );
	}
} );
