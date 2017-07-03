import gulp from 'gulp';
import gutil from 'gulp-util';
import cache from 'gulp-cached';
import progeny from 'gulp-progeny';
import yargs from 'yargs';
import { join } from 'path';
import { paths } from '../utils/get-package-data';
import sass from 'gulp-sass';
import sourcemaps from 'gulp-sourcemaps';
import flatten from 'gulp-flatten';
import gulpIf from 'gulp-if';
import postcss from 'gulp-postcss';
import cssnext from 'postcss-cssnext';
import pxtorem from 'postcss-pxtorem';
import autoprefixer from 'autoprefixer';
//import assets from 'postcss-assets';

const isDev      = 'dev' === yargs.argv.env,
	  processors = [
		  cssnext( { warnForDuplicates: false } ),
		  autoprefixer(),
		  pxtorem( {
			  rootValue:         16,
			  unitPrecision:     5,
			  propList:          [ '*' ],
			  selectorBlackList: [],
			  replace:           true,
			  mediaQuery:        true,
			  minPixelValue:     2
		  } )
	  ];

//if ( undefined !== paths.images.dest ) {
//	processors.push(
//		assets( {
//			basePath:  '/',
//			loadPaths: paths.images.dest
//		} )
//	);
//}

gulp.task( 'css', [ 'css-lint' ], () => {
	if ( undefined === paths.css || undefined === paths.css.glob || undefined === paths.css.src || undefined === paths.css.dest ) {
		gutil.log( `Missing path in '${ gutil.colors.cyan( 'css' ) }' task, aborting!` );
		return null;
	}

	return gulp
		.src( join( paths.css.src, paths.css.glob ) )

		// Caching and incremental building (progeny) in Gulp.
		.pipe( gulpIf( isDev, cache( 'css-task-cache' ) ) )
		.pipe( gulpIf( isDev, progeny() ) )

		// Actual SASS compilation.
		.pipe( gulpIf ( isDev, sourcemaps.init() ) )
		.pipe( sass( {
			includePaths: paths.css.includePaths,
			outputStyle: isDev ? 'expanded' : 'compressed'
		} ).on( 'error', sass.logError ) )
		.pipe( postcss( processors ) )
		.pipe( gulpIf ( isDev, sourcemaps.write( '' ) ) )

		// Flatten directories.
		.pipe( flatten() )
		.pipe( gulp.dest( paths.css.dest ) );

		/*
		 * If you generate source maps to a separate `.map` file you need to add `{match: '** / *.css'}` option to stream.
		 * These files end up being sent down stream and when browserSync.stream() receives them, it will attempt
		 * a full page reload (as it will not find any .map files in the DOM).
		 */
		//.pipe( gulpIf( isDev, bs.stream() ) );
} );
