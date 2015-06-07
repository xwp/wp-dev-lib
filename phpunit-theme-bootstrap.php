<?php

$_tests_dir = getenv( 'WP_TESTS_DIR' );
if ( empty( $_tests_dir ) ) {
	$_tests_dir = '/tmp/wordpress-tests-lib';
}

if ( ! file_exists( $_tests_dir . '/includes/' ) ) {
	trigger_error( 'Unable to locate wordpress-tests-lib', E_USER_ERROR );
}
require_once $_tests_dir . '/includes/functions.php';

if ( defined( 'WP_TEST_ACTIVATED_THEME' ) ) {
	$GLOBALS['wp_tests_options'] = array(
		'stylesheet' => WP_TEST_ACTIVATED_THEME,
		'template' => WP_TEST_ACTIVATED_THEME
	);
}

require $_tests_dir . '/includes/bootstrap.php';
