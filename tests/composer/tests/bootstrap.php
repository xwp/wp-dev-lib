<?php

$_tests_dir = getenv( 'WP_TESTS_DIR' );

if ( ! file_exists( $_tests_dir . '/includes' ) ) {
	trigger_error( 'Unable to locate wordpress-tests-lib', E_USER_ERROR );
}

// @see https://core.trac.wordpress.org/browser/trunk/tests/phpunit/includes/functions.php
require_once $_tests_dir . '/includes/functions.php';

tests_add_filter( 'muplugins_loaded', function() {
	global $wpdb;
	$results = $wpdb->get_results( "SELECT * FROM {$wpdb->prefix}options" );
	var_dump( $results );
} );

// @see https://core.trac.wordpress.org/browser/trunk/tests/phpunit/includes/bootstrap.php
require $_tests_dir . '/includes/bootstrap.php';
