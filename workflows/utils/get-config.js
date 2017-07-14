import fs from 'fs';
import yargs from 'yargs';

const json = JSON.parse( fs.readFileSync( './package.json' ) ),
	  env = yargs.argv.env,
	  workflow = yargs.argv.workflow,
	  browserslist = json.browserslist;

let tasks,
	cwd = '',
	isTest = false,
	isProd = false,
	isDev  = false;

switch ( env ) {
case 'test':
	isTest = true;
	break;
case 'prod':
case 'production':
	isProd = true;
	break;
default:
	isDev = true;
}

if ( undefined !== workflow && undefined !== json.workflows[ workflow ] ) {
	tasks = json.workflows[ workflow ];
}
if ( undefined !== tasks.cwd ) {
	cwd = tasks.cwd;
}

export { json, tasks, env, cwd, isDev, isTest, isProd, workflow, browserslist };
