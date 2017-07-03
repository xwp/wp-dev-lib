import fs from 'fs';

const json = JSON.parse( fs.readFileSync( './package.json' ) );
const paths = json['paths'];

export { json, paths };
