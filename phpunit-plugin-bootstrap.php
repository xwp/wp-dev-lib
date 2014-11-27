<?php

$_tests_dir = getenv( 'WP_TESTS_DIR' );
if ( empty( $_tests_dir ) ) {
	$_tests_dir = '/tmp/wordpress-tests-lib';
}

if ( ! file_exists( $_tests_dir . '/includes/' ) ) {
	trigger_error( 'Unable to locate wordpress-tests-lib', E_USER_ERROR );
}
require_once $_tests_dir . '/includes/functions.php';

$_plugin_dir = dirname( __DIR__ );
$_plugin_slug = basename( $_plugin_dir );
$_plugin_file = sprintf( '%s/%s.php', $_plugin_dir, $_plugin_slug );
if ( ! file_exists( $_plugin_file ) ) {
	trigger_error( "Unable to locate plugin file at $_plugin_file", E_USER_ERROR );
}

tests_add_filter( 'muplugins_loaded', function () use ( $_plugin_file ) {
	if ( file_exists( ABSPATH . '/wp-content/themes/vip/plugins/vip-init.php' ) ) {
		// @todo Load VIP files and make sure Jetpack is installed/activated
	}

	require_once $_plugin_file;
} );

require $_tests_dir . '/includes/bootstrap.php';
