<?php

$_tests_dir = getenv( 'WP_TESTS_DIR' );
if ( empty( $_tests_dir ) ) {
	$_tests_dir = '/tmp/wordpress-tests-lib';
}

if ( ! file_exists( $_tests_dir . '/includes/' ) ) {
	trigger_error( 'Unable to locate wordpress-tests-lib', E_USER_ERROR );
}
require_once $_tests_dir . '/includes/functions.php';

/**
 * Locate plugin file and autoload
 */
function xwp_autoload_plugin() {
	$plugin_dir = dirname( __DIR__ );
	$plugin_slug = basename( $plugin_dir );
	$plugin_file = sprintf( '%s/%s.php', $plugin_dir, $plugin_slug );
	if ( ! file_exists( $plugin_file ) ) {
		trigger_error( "Unable to locate plugin file at $plugin_file", E_USER_ERROR );
	}

	// Force vip-init.php to be loaded on VIP quickstart
	if ( file_exists( WP_CONTENT_DIR . '/themes/vip/plugins/vip-init.php' ) ) {
		require_once( WP_CONTENT_DIR . '/themes/vip/plugins/vip-init.php' );
	}

	// Load this plugin
	require_once $plugin_file;
}
tests_add_filter( 'muplugins_loaded', 'xwp_autoload_plugin' );

/**
 * Force plugins defined in a constant (supplied by phpunit.xml) to be active at runtime.
 *
 * @filter site_option_active_sitewide_plugins
 * @filter option_active_plugins
 *
 * @param array $active_plugins
 * @return array
 */
function xwp_filter_active_plugins_for_phpunit( $active_plugins ) {
	$forced_active_plugins = array();
	if ( file_exists( WP_CONTENT_DIR . '/themes/vip/plugins/vip-init.php' ) && defined( 'WP_TEST_VIP_QUICKSTART_ACTIVATED_PLUGINS' ) ) {
		$forced_active_plugins = preg_split( '/\s*,\s*/', WP_TEST_VIP_QUICKSTART_ACTIVATED_PLUGINS );
	} else if ( defined( 'WP_TEST_ACTIVATED_PLUGINS' ) ) {
		$forced_active_plugins = preg_split( '/\s*,\s*/', WP_TEST_ACTIVATED_PLUGINS );
	}
	if ( ! empty( $forced_active_plugins ) ) {
		foreach ( $forced_active_plugins as $forced_active_plugin ) {
			$active_plugins[ "$forced_active_plugin" ] = time();
		}
	}
	return $active_plugins;
}
tests_add_filter( 'site_option_active_sitewide_plugins', 'xwp_filter_active_plugins_for_phpunit' );
tests_add_filter( 'option_active_plugins', 'xwp_filter_active_plugins_for_phpunit' );

require $_tests_dir . '/includes/bootstrap.php';
