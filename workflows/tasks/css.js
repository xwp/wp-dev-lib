import gulp from 'gulp';
import cache from 'gulp-cached';
import progeny from 'gulp-progeny';
import { tasks, isDev } from '../utils/get-config';
import sass from 'gulp-sass';
import sourcemaps from 'gulp-sourcemaps';
import gulpIf from 'gulp-if';
import postcss from 'gulp-postcss';
import cssnext from 'postcss-cssnext';
import pxtorem from 'postcss-pxtorem';
import autoprefixer from 'autoprefixer';
//import assets from 'postcss-assets';
import TaskHelper from '../utils/TaskHelper';

const task = new TaskHelper( {
	name: 'css',
	requiredPaths: [ 'src', 'dest' ],
	config: tasks
} );

if ( undefined !== task.config ) {
	const processors = [
			  cssnext( { warnForDuplicates: false } ),
			  autoprefixer(),
			  pxtorem( {
				  rootValue:         16,
				  unitPrecision:     5,
				  propList:          ['*'],
				  selectorBlackList: [],
				  replace:           true,
				  mediaQuery:        true,
				  minPixelValue:     2
			  } )
		  ];

	let preTasks = [];

	if ( undefined !== task.config.enableLinter && true === task.config.enableLinter ) {
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

	gulp.task( task.name, gulp.series( preTasks, () => {
		if ( ! task.isValid() ) {
			return null;
		}

		return task.start()

			// Caching and incremental building (progeny) in Gulp.
			.pipe( gulpIf( isDev, cache( task.cacheName ) ) )
			.pipe( gulpIf( isDev, progeny() ) )

			// Actual SASS compilation.
			.pipe( gulpIf( isDev, sourcemaps.init() ) )
			.pipe( sass( {
				includePaths: task.config.includePaths,
				outputStyle:  isDev ? 'expanded' : 'compressed'
			} ).on( 'error', sass.logError ) )
			.pipe( postcss( processors ) )
			.pipe( gulpIf( isDev, sourcemaps.write( '' ) ) )

			.pipe( task.end() );

		/*
		 * If you generate source maps to a separate `.map` file you need to add `{match: '** / *.css'}` option to stream.
		 * These files end up being sent down stream and when browserSync.stream() receives them, it will attempt
		 * a full page reload (as it will not find any .map files in the DOM).
		 */
		//.pipe( gulpIf( isDev, bs.stream() ) );
	} ) );
}
