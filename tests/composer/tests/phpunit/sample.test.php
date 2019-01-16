<?php
/**
 * Sample PHPUnit test.
 */

class Sample_Test extends WP_UnitTestCase {

	function test_tests() {
		$this->assertContains( 'http', site_url(), 'Site URL contains a valid protocol.' );
	}

}
