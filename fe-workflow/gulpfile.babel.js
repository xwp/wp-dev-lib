import requireDir from 'require-dir';
import gulp from 'gulp';
import runSequence from 'run-sequence';
import yargs from 'yargs';

// Define tasks for each environment.
const tasks = {
	prod: [
		'clean',
		[ 'js-lint' ],
		[ 'images', 'css', 'js' ],
		'assets',
		'size-report'
	],
	dev:  [
		'clean',
		[ 'css' ]
	]
};

// Load all Gulp tasks from `tasks` dir.
requireDir( 'tasks' );

// To add a new task, simply create a new task file in `tasks` folder.
gulp.task( 'default', done => {
	const taskList = 'dev' === yargs.argv.env ? tasks.dev : tasks.prod;

	runSequence( ...taskList, done );
} );
