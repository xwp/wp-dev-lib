<?php
/**
 * Sample PHPUnit test.
 */

class Sample_Test extends WP_UnitTestCase {

	function test_tests() {
		global $wpdb;
		$results = $wpdb->get_results( "SELECT * FROM {$wpdb->prefix}options" );
		print_r( $results );
		$this->assertTrue( true );
	}

}
