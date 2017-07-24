export const sortTasks = function( allTasks ) {
	let tasks = allTasks, before = [], after = [];

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
