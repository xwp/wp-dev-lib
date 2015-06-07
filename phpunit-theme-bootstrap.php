<?php

$_tests_dir = getenv( 'WP_TESTS_DIR' );
if ( empty( $_tests_dir ) ) {
	$_tests_dir = '/tmp/wordpress-tests-lib';
}

if ( ! file_exists( $_tests_dir . '/includes/' ) ) {
	trigger_error( 'Unable to locate wordpress-tests-lib', E_USER_ERROR );
}
require_once $_tests_dir . '/includes/functions.php';

$GLOBALS['wp_tests_options'] = array(
	'stylesheet' => 'yourthemeslug',
	'template' => 'yourthemeslug'
);

require $_tests_dir . '/includes/bootstrap.php';
