<?php
/**
 * Utility class for parsing git diffs and for filtering reports to lines in diffs.
 *
 * @package wordpress
 */

/**
 * Class Git_Patch_Checker
 *
 * @package wordpress
 */
class Git_Patch_Checker {

	/**
	 * Parse the ranges represented by a zero-context (--unified=0) diff.
	 *
	 * @param string $diff  Diff with --unified=0.
	 * @return array
	 */
	static public function parse_diff_ranges( $diff ) {
		$ranges = array();
		$current_file_path = null;

		foreach ( preg_split( "/\n/", $diff ) as $line ) {
			if ( preg_match( '#^\+\+\+ (?P<file_path>.+)#', $line, $matches ) ) {
				$current_file_path = $matches['file_path'];
				continue;
			}
			if ( empty( $current_file_path ) ) {
				continue;
			}
			if ( preg_match( '#^@@ -(\d+)(?:,(\d+))? \+(?P<line_number>\d+)(?:,(?P<line_count>\d+))? @@#', $line, $matches ) ) {
				if ( empty( $matches['line_count'] ) ) {
					$matches['line_count'] = 1;
				}
				$start_line = intval( $matches['line_number'] );
				$end_line = intval( $matches['line_number'] ) + max( 0, intval( $matches['line_count'] ) - 1 );
				$file_path = $current_file_path;
				$ranges[] = compact( 'file_path', 'start_line', 'end_line' );
			}
		}

		return $ranges;
	}

	/**
	 * Parse and select the lines of a lint report that lie within diff ranges.
	 *
	 * @param string $report       Diff report string.
	 * @param array  $diff_ranges  Ranges for the diff.
	 * @return array
	 */
	static public function filter_report_for_patch_ranges( $report, $diff_ranges ) {
		$filtered_report_lines = array();

		foreach ( explode( "\n", $report ) as $line ) {
			$matched = (
				preg_match( '#^(?P<file_path>.+):(?P<line_number>\d+):\d+:.+$$#', $line, $matches )
				||
				preg_match( '/^(?P<file_path>.+): line (?P<line_number>\d+),/', $line, $matches )
			);
			if ( ! $matched ) {
				continue;
			}
			$file_path = realpath( $matches['file_path'] );
			if ( ! array_key_exists( $file_path, $diff_ranges ) ) {
				continue;
			}
			$line_number = intval( $matches['line_number'] );
			$matched = false;
			foreach ( $diff_ranges[ $file_path ] as $range ) {
				if ( $line_number >= $range['start_line'] && $line_number <= $range['end_line'] ) {
					$matched = true;
					break;
				}
			}
			if ( $matched ) {
				$filtered_report_lines[] = $matches;
			}
		}

		return $filtered_report_lines;
	}
}
