import gulp from 'gulp';
import gutil from 'gulp-util';
import cache from 'gulp-cached';
import progeny from 'gulp-progeny';
import { join } from 'path';
import { tasks, isDev } from '../utils/get-config';
import sass from 'gulp-sass';
import sourcemaps from 'gulp-sourcemaps';
import flatten from 'gulp-flatten';
import gulpIf from 'gulp-if';
import postcss from 'gulp-postcss';
import cssnext from 'postcss-cssnext';
import pxtorem from 'postcss-pxtorem';
import autoprefixer from 'autoprefixer';
//import assets from 'postcss-assets';

if ( undefined !== tasks.css ) {
	const processors = [
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

	let preTasks = [];

	if ( undefined !== tasks.css.enableStylelinter && true === tasks.css.enableStylelinter ) {
		preTasks.push( 'css-lint' );
	}

//if ( undefined !== tasks.images.dest ) {
//	processors.push(
//		assets( {
//			basePath:  '/',
//			loadtasks: tasks.images.dest
//		} )
//	);
//}

	gulp.task( 'css', preTasks, () => {
		if ( undefined === tasks.css || undefined === tasks.css.glob || undefined === tasks.css.src || undefined === tasks.css.dest ) {
			gutil.log( `Missing path in '${ gutil.colors.cyan( 'css' ) }' task, aborting!` );
			return null;
		}

		return gulp
			.src( join( tasks.css.src, tasks.css.glob ) )

			// Caching and incremental building (progeny) in Gulp.
			.pipe( gulpIf( isDev, cache( 'css-task-cache' ) ) )
			.pipe( gulpIf( isDev, progeny() ) )

			// Actual SASS compilation.
			.pipe( gulpIf( isDev, sourcemaps.init() ) )
			.pipe( sass( {
				includePaths: tasks.css.includePaths,
				outputStyle:  isDev ? 'expanded' : 'compressed'
			} ).on( 'error', sass.logError ) )
			.pipe( postcss( processors ) )
			.pipe( gulpIf( isDev, sourcemaps.write( '' ) ) )

			// Flatten directories.
			.pipe( flatten() )
			.pipe( gulp.dest( tasks.css.dest ) );

		/*
		 * If you generate source maps to a separate `.map` file you need to add `{match: '** / *.css'}` option to stream.
		 * These files end up being sent down stream and when browserSync.stream() receives them, it will attempt
		 * a full page reload (as it will not find any .map files in the DOM).
		 */
		//.pipe( gulpIf( isDev, bs.stream() ) );
	} );
}
