import fs from 'fs';
import yargs from 'yargs';

const json = JSON.parse( fs.readFileSync( './package.json' ) ),
	  env = yargs.argv.env,
	  isDev = 'development' === env || 'dev' === env,
	  isTest = 'test' === env,
	  isProd = 'production' === env || 'prod' === env,
	  workflow = yargs.argv.workflow,
	  browserslist = json.browserslist;

let tasks;
if ( undefined !== workflow && undefined !== json.workflows[ workflow ] ) {
	tasks = json.workflows[ workflow ];
}
if ( undefined !== env && undefined !== tasks[ env ] ) {
	tasks = tasks[ env ];
}

export { json, tasks, env, isDev, isTest, isProd, workflow, browserslist };
