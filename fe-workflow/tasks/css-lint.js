import gulp from 'gulp';
import gutil from 'gulp-util';
import cache from 'gulp-cached';
import { join } from 'path';
import { tasks, env } from '../utils/get-package-data';
import gulpIf from 'gulp-if';
import postcss from 'gulp-postcss';
import reporter from 'postcss-reporter';
import scss from 'postcss-scss';
import stylelint from 'stylelint';

if ( undefined !== tasks.css ) {
	const isDev = 'dev' === env;

	gulp.task( 'css-lint', () => {
		if ( undefined === tasks.css.glob || undefined === tasks.css.src ) {
			gutil.log( `Missing path in '${ gutil.colors.cyan( 'css-lint' ) }' task, aborting!` );
			return null;
		}

		return gulp
			.src( join( tasks.css.src, tasks.css.glob ) )

			// Caching and incremental building (progeny) in Gulp.
			.pipe( gulpIf( isDev, cache( 'css-lint-task-cache' ) ) )

			// Lint styles.
			.pipe( postcss( [
				stylelint(),
				reporter( { clearMessages: true } )
			], { syntax: scss } ) );
	} );
}
