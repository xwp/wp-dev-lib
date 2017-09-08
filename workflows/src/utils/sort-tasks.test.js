/* eslint-env jest */

import { sortTasks } from './sort-tasks';

describe( 'sortTasks()', () => {
	test( 'returns before and main tasks', () => {
		expect( sortTasks( [ 'clean', 'js', 'css' ] ) ).toEqual( {
			before: [ 'clean' ],
			tasks:  [ 'js', 'css' ],
			after:  []
		} );
	} );

	test( 'returns before, after and main tasks', () => {
		expect( sortTasks( [ 'watch', 'clean', 'js', 'css' ] ) ).toEqual( {
			before: [ 'clean' ],
			tasks:  [ 'js', 'css' ],
			after:  [ 'watch' ]
		} );
	} );

	test( 'returns after and main tasks', () => {
		expect( sortTasks( [ 'watch', 'js', 'css' ] ) ).toEqual( {
			before: [],
			tasks:  [ 'js', 'css' ],
			after:  [ 'watch' ]
		} );
	} );

	test( 'returns after tasks only', () => {
		expect( sortTasks( [ 'watch' ] ) ).toEqual( {
			before: [],
			tasks:  [],
			after:  [ 'watch' ]
		} );
	} );

	test( 'returns main tasks only', () => {
		expect( sortTasks( [ 'css' ] ) ).toEqual( {
			before: [],
			tasks:  [ 'css' ],
			after:  []
		} );
	} );

	test( 'returns before tasks only', () => {
		expect( sortTasks( [ 'clean' ] ) ).toEqual( {
			before: [ 'clean' ],
			tasks:  [],
			after:  []
		} );
	} );

	test( 'specified tasks are ignored', () => {
		expect( sortTasks( [ 'watch', 'clean', 'js', 'css' ], [ 'css' ] ) ).toEqual( {
			before: [ 'clean' ],
			tasks:  [ 'js' ],
			after:  [ 'watch' ]
		} );
	} );

	test( 'specified tasks are ignored', () => {
		expect( sortTasks( [ 'watch', 'clean', 'js', 'css' ], [ 'clean' ] ) ).toEqual( {
			before: [],
			tasks:  [ 'js', 'css' ],
			after:  [ 'watch' ]
		} );
	} );

	test( 'specified tasks are ignored', () => {
		expect( sortTasks( [ 'watch', 'clean', 'js', 'css' ], [ 'watch' ] ) ).toEqual( {
			before: [ 'clean' ],
			tasks:  [ 'js', 'css' ],
			after:  []
		} );
	} );
} );
