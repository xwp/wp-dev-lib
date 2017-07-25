/**
 * Split tasks into 3 categories: main tasks, before and after.
 *
 * @param {Array} allTasks Set of all tasks
 * @param {Array} ignoredTasks Tasks to ignore
 * @return {{before: Array, tasks: Array, after: Array}} Categorized tasks object
 */
export const sortTasks = function( allTasks, ignoredTasks ) {
	let tasks = allTasks, before = [], after = [];

	if ( undefined !== ignoredTasks ) {
		tasks = tasks.filter( task => ! ignoredTasks.includes( task ) );
	}

	if ( tasks.includes( 'clean' ) ) {
		before.push( 'clean' );
		tasks = tasks.filter( task => 'clean' !== task );
	}

	if ( tasks.includes( 'watch' ) ) {
		after.push( 'watch' );
		tasks = tasks.filter( task => 'watch' !== task );
	}

	return { before, tasks, after };
};
