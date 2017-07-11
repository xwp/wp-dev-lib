import gulp from 'gulp';
import cache from 'gulp-cached';
import { tasks, isDev, isProd } from '../utils/get-config';
import eslint from 'gulp-eslint';
import gulpIf from 'gulp-if';
import TaskHelper from '../utils/TaskHelper';

const task = new TaskHelper( {
	name: 'js-lint',
	requiredPaths: ['src'],
	config: tasks
} );

if ( undefined !== task.config ) {
	gulp.task( task.name, () => {
		if ( ! task.isValid() ) {
			return null;
		}

		return task.start()
			.pipe( gulpIf( isDev, cache( task.cacheName ) ) )
			.pipe( eslint() )
			.pipe( eslint.format() )
			.pipe( gulpIf( isProd, eslint.failAfterError() ) );
	} );
}

