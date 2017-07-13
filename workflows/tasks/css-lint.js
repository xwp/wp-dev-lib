import gulp from 'gulp';
import cache from 'gulp-cached';
import { tasks, isDev } from '../utils/get-config';
import gulpIf from 'gulp-if';
import postcss from 'gulp-postcss';
import reporter from 'postcss-reporter';
import scss from 'postcss-scss';
import stylelint from 'stylelint';
import TaskHelper from '../utils/TaskHelper';

const task = new TaskHelper( {
	name: 'css-lint',
	requiredPaths: ['src'],
	config: tasks,
	configSlug: 'css'
} );

if ( undefined !== task.config ) {
	gulp.task( task.name, () => {
		if ( ! task.isValid() ) {
			return null;
		}

		return task.start()
			.pipe( gulpIf( isDev, cache( task.cacheName ) ) )
			.pipe( postcss( [
				stylelint(),
				reporter( { clearMessages: true } )
			], { syntax: scss } ) );
	} );
}
