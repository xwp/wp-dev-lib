import fs from 'fs';
import yargs from 'yargs';

const json = JSON.parse( fs.readFileSync( './package.json' ) ),
	  env = yargs.argv.env,
	  workflow = yargs.argv.workflow;

let tasks;
if ( undefined !== workflow && undefined !== json.workflows[ workflow ] ) {
	tasks = json.workflows[ workflow ];
}
if ( undefined !== env && undefined !== tasks[ env ] ) {
	tasks = tasks[ env ];
}

export { json, tasks, env, workflow };
