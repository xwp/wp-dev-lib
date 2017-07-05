import gulp from 'gulp';
import cache from 'gulp-cached';
import { tasks, env } from '../utils/get-package-data';
import gulpIf from 'gulp-if';
import eslint from 'gulp-eslint';
import gutil from 'gulp-util';

if ( undefined !== tasks[ 'js-lint' ] ) {
	const isDev = 'dev' === env,
		  isProd = 'prod' === env;

	gulp.task( 'js-lint', () => {
		if ( undefined === tasks[ 'js-lint' ].src ) {
			gutil.log( `Missing path in '${ gutil.colors.cyan( 'js-lint' ) }' task, aborting!` );
			return null;
		}

		return gulp
			.src( tasks[ 'js-lint' ].src )

			// Cache.
			.pipe( gulpIf( isDev, cache( 'js-lint-task-cache' ) ) )

			// Lint JS.
			.pipe( eslint() )
			.pipe( eslint.format() )
			.pipe( gulpIf( isProd, eslint.failAfterError() ) );
	} );
}
