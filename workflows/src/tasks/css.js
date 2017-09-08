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
import assets from 'postcss-assets';
import TaskHelper from '../utils/TaskHelper';

const task = new TaskHelper( {
	name: 'css',
	requiredPaths: [ 'src', 'dest' ],
	config: tasks
} );

if ( undefined !== task.config ) {
	let fn = function() {
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
				includePaths: undefined !== task.config.includePaths ? task.config.includePaths : [],
				outputStyle:  isDev ? 'expanded' : 'compressed'
			} ).on( 'error', sass.logError ) )
			.pipe( postcss( getProcessors( task.config.postcssProcessors ) ) )
			.pipe( gulpIf( isDev, sourcemaps.write( '' ) ) )

			.pipe( task.end() );
	};

	fn.displayName = 'css-compile';

	if ( undefined !== task.config.enableLinter && true === task.config.enableLinter ) {
		gulp.task( 'css', gulp.series( 'css-lint', fn ) );
	} else {
		gulp.task( 'css', fn );
	}
}

function getProcessors( settings ) {
	let processors = [], defaults, s;

	defaults = {
		cssnext:      {
			warnForDuplicates: false
		},
		autoprefixer: {},
		pxtorem:      {
			rootValue:         16,
			unitPrecision:     5,
			propList:          [ '*' ],
			selectorBlackList: [],
			replace:           true,
			mediaQuery:        true,
			minPixelValue:     2
		},
		assets:       {
			relative: true
		}
	};

	if ( false !== settings.cssnext ) {
		s = true === settings.cssnext ? {} : settings.cssnext;
		processors.push( cssnext( Object.assign( defaults.cssnext, s ) ) );
	}

	if ( false !== settings.autoprefixer ) {
		s = true === settings.autoprefixer ? {} : settings.autoprefixer;
		processors.push( autoprefixer( Object.assign( defaults.autoprefixer, s ) ) );
	}

	if ( false !== settings.pxtorem ) {
		s = true === settings.pxtorem ? {} : settings.pxtorem;
		processors.push( pxtorem( Object.assign( defaults.pxtorem, s ) ) );
	}

	if ( false !== settings.assets ) {
		s = true === settings.assets ? {} : settings.assets;
		processors.push( assets( Object.assign( defaults.assets, s ) ) );
	}

	return processors;
}
