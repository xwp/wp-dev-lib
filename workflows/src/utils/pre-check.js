import gutil from 'gulp-util';
import validateNode from 'validate-node-version';
import { workflow, env } from './get-config';

export const preCheck = function() {
	const nodeTest = validateNode(),
		  exitCode = 1;

	if ( ! nodeTest.satisfies ) {
		gutil.log( gutil.colors.red( nodeTest.message ) );
		process.exit( exitCode );
	}

	if ( undefined === workflow ) {
		gutil.log( gutil.colors.red( `No workflow provided, aborting!` ) );
		process.exit( exitCode );
	} else {
		gutil.log( `Using '${ gutil.colors.yellow( workflow ) }' workflow...` );
	}

	if ( undefined !== env ) {
		gutil.log( `Using '${ gutil.colors.yellow( env ) }' environment...` );
	}
};
