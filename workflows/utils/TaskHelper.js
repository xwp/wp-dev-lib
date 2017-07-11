import gulp from 'gulp';
import gutil from 'gulp-util';
import { join } from 'path';
import { cwd } from './get-config';

export default class TaskHelper {
	constructor( { name = '', requiredPaths = [], config = null } ) {
		if ( null === config ) {
			gutil.log(  gutil.colors.red( 'The task template is missing a configuration.' ) );
			return;
		}

		this._name = name;
		this._requiredPaths = requiredPaths;
		this._config = config;
	}

	get config() {
		return '' !== this.name ? this._config[ this.name ] : this._config;
	}

	get name() {
		return this._name;
	}

	get requiredPaths() {
		return this._requiredPaths;
	}

	get hasPathsDefined() {
		return this.requiredPaths.every( path => undefined !== this.config[ path ] );
	}

	get src() {
		const srcList = Array.isArray( this.config.src ) ? this.config.src : [ this.config.src ],
			  src = srcList.map( path => join( cwd, path ) );

		return src;
	}

	get entries() {
		const entriesList = Array.isArray( this.config.entries ) ? this.config.entries : [ this.config.entries ],
			  entries = entriesList.map( path => join( cwd, path ) );

		return entries;
	}

	get base() {
		return undefined === this.config.base ? '' : join( cwd, this.config.base );
	}

	get dest() {
		return this.config.dest;
	}

	get cacheName() {
		return `${ this.name }-task-cache`;
	}

	isValid() {
		if ( ! this.hasPathsDefined ) {
			gutil.log( `Missing paths in '${ gutil.colors.red( this.name ) }' task, aborting!` );
			return false;
		}
		return true;
	}

	start() {
		return gulp.src( this.src, { base: this.base } );
	}

	end() {
		return gulp.dest( this.dest, { cwd } );
	}
}
