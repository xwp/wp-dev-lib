#!/usr/bin/env php
<?php
/**
 * INPUT: Piped from `git diff --no-prefix --unified=0`
 * OUTPUT: Multiple lines in the form of "path/to/file.ext:123-456"
 *
 * @package wordpress
 */

require_once dirname( __FILE__ ) . '/class-git-patch-checker.php';

$patch_checker = new Git_Patch_Checker();
$ranges = $patch_checker->parse_diff_ranges( file_get_contents( 'php://stdin' ) );
foreach ( $ranges as $range ) {
	printf( "%s:%d-%d\n", $range['file_path'], $range['start_line'], $range['end_line'] );
}
