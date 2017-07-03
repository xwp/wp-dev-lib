import gulp from 'gulp';
import gutil from 'gulp-util';
import cache from 'gulp-cached';
import yargs from 'yargs';
import { join } from 'path';
import { paths } from '../utils/get-package-data';
import gulpIf from 'gulp-if';
import postcss from 'gulp-postcss';
import reporter from 'postcss-reporter';
import scss from 'postcss-scss';
import stylelint from 'stylelint';

const isDev = 'dev' === yargs.argv.env;

gulp.task( 'css-lint', () => {
	if ( undefined === paths.css || undefined === paths.css.glob || undefined === paths.css.src ) {
		gutil.log( `Missing path in '${ gutil.colors.cyan( 'css-lint' ) }' task, aborting!` );
		return null;
	}

	return gulp
		.src( join( paths.css.src, paths.css.glob ) )

		// Caching and incremental building (progeny) in Gulp.
		.pipe( gulpIf( isDev, cache( 'css-lint-task-cache' ) ) )

		// Lint styles.
		.pipe( postcss( [
			stylelint(),
			reporter( { clearMessages: true } )
		], { syntax: scss } ) );
} );
