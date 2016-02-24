<?php
/**
 * Lightweight WordPress readme.txt parser and converter to Markdown
 * The WordPress-Plugin-Readme-Parser project is too heavy and has too many dependencies for what we need (we don't need conversion to HTML)
 * @link https://github.com/markjaquith/WordPress-Plugin-Readme-Parser Alternative to WordPress-Plugin-Readme-Parser
 * @version 1.1.1
 * @author Weston Ruter <weston@xwp.co> (@westonruter)
 * @copyright Copyright (c) 2013, XWP <https://xwp.co/>
 * @license GPLv2+
 */

class WordPress_Readme_Parser {
	public $path;
	public $source;
	public $title = '';
	public $short_description = '';
	public $metadata = array();
	public $sections = array();

	function __construct( $args = array() ) {
		$args = array_merge( get_object_vars( $this ), $args );
		foreach ( $args as $key => $value ) {
			$this->$key = $value;
		}

		// @codingStandardsIgnoreStart
		$this->source = file_get_contents( $this->path );
		// @codingStandardsIgnoreEnd
		if ( ! $this->source ) {
			throw new Exception( 'readme.txt was empty or unreadable' );
		}

		// Parse metadata
		$syntax_ok = preg_match( '/^=== (.+?) ===\n(.+?)\n\n(.+?)\n(.+)/s', $this->source, $matches );
		if ( ! $syntax_ok ) {
			throw new Exception( 'Malformed metadata block' );
		}
		$this->title = $matches[1];
		$this->short_description = $matches[3];
		$readme_txt_rest = $matches[4];
		$this->metadata = array_fill_keys( array( 'Contributors', 'Tags', 'Requires at least', 'Tested up to', 'Stable tag', 'License', 'License URI' ), null );
		foreach ( explode( "\n", $matches[2] ) as $metadatum ) {
			if ( ! preg_match( '/^(.+?):\s+(.+)$/', $metadatum, $metadataum_matches ) ) {
				throw new Exception( "Parse error in $metadatum" );
			}
			list( $name, $value )  = array_slice( $metadataum_matches, 1, 2 );
			$this->metadata[ $name ] = $value;
		}
		$this->metadata['Contributors'] = array_filter( preg_split( '/\s*,\s*/', $this->metadata['Contributors'] ) );
		$this->metadata['Tags'] = array_filter( preg_split( '/\s*,\s*/', $this->metadata['Tags'] ) );

		$syntax_ok = preg_match_all( '/(?:^|\n)== (.+?) ==\n(.+?)(?=\n== |$)/s', $readme_txt_rest, $section_matches, PREG_SET_ORDER );
		if ( ! $syntax_ok ) {
			throw new Exception( 'Failed to parse sections from readme.txt' );
		}
		foreach ( $section_matches as $section_match ) {
			array_shift( $section_match );

			$heading     = array_shift( $section_match );
			$body        = trim( array_shift( $section_match ) );
			$subsections = array();

			// Check if there is front matter
			if ( preg_match( '/^(\s*[^=].+?)(?=\n=|$)(.*$)/s', $body, $matches ) ) {
				$body = $matches[1];
				$subsection_search_area = $matches[2];
			} else {
				$subsection_search_area = $body;
				$body = null;
			}

			// Parse subsections
			if ( preg_match_all( '/(?:^|\n)= (.+?) =\n(.+?)(?=\n= |$)/s', $subsection_search_area, $subsection_matches, PREG_SET_ORDER ) ) {
				foreach ( $subsection_matches as $subsection_match ) {
					array_shift( $subsection_match );
					$subsections[] = array(
						'heading' => array_shift( $subsection_match ),
						'body' => trim( array_shift( $subsection_match ) ),
					);
				}
			}

			$this->sections[] = compact( 'heading', 'body', 'subsections' );
		}
	}

	/**
	 * Convert the parsed readme.txt into Markdown
	 * @param array|string [$params]
	 * @return string
	 */
	function to_markdown( $params = array() ) {
		$that = $this;

		$general_section_formatter = function ( $body ) use ( $params ) {
			$body = preg_replace(
				'#\[youtube\s+(?:https?://www\.youtube\.com/watch\?v=|https?://youtu\.be/)(.+?)\]#',
				'[![Play video on YouTube](https://i1.ytimg.com/vi/$1/hqdefault.jpg)](https://www.youtube.com/watch?v=$1)',
				$body
			);
			// Convert <pre lang="php"> into GitHub-flavored ```php markdown blocks
			$body = preg_replace(
				'#\n?<pre lang="(\w+)">\n?(.+?)\n?</pre>\n?#s',
				"\n" . '```$1' . "\n" . '$2' . "\n" . '```' . "\n",
				$body
			);
			return $body;
		};

		// Parse sections
		$section_formatters = array(
			'Screenshots' => function ( $body ) use ( $that, $params ) {
				$body = trim( $body );
				$new_body = '';
				if ( ! preg_match_all( '/^\d+\. (.+?)$/m', $body, $screenshot_matches, PREG_SET_ORDER ) ) {
					throw new Exception( 'Malformed screenshot section' );
				}
				foreach ( $screenshot_matches as $i => $screenshot_match ) {
					$img_extensions = array( 'jpg', 'gif', 'png' );
					foreach ( $img_extensions as $ext ) {
						$filepath = sprintf( '%s/screenshot-%d.%s', $params['assets_dir'], $i + 1, $ext );
						if ( file_exists( dirname( $that->path ) . DIRECTORY_SEPARATOR . $filepath ) ) {
							break;
						} else {
							$filepath = null;
						}
					}
					if ( empty( $filepath ) ) {
						continue;
					}

					$screenshot_name = $screenshot_match[1];
					$new_body .= sprintf( "### %s\n", $screenshot_name );
					$new_body .= "\n";
					$new_body .= sprintf( "![%s](%s)\n", $screenshot_name, $filepath );
					$new_body .= "\n";
				}
				return $new_body;
			},
		);

		// Format metadata
		$formatted_metadata = array_filter( $this->metadata );
		$formatted_metadata['Contributors'] = join(
			', ',
			array_map(
				function ( $contributor ) {
					$contributor = strtolower( $contributor );
					// @todo Map to GitHub account
					return sprintf( '[%1$s](https://profiles.wordpress.org/%1$s)', $contributor );
				},
				$this->metadata['Contributors']
			)
		);
		if ( ! empty( $this->metadata['Tags'] ) ) {
			$formatted_metadata['Tags'] = join(
				', ',
				array_map(
					function ( $tag ) {
						return sprintf( '[%1$s](https://wordpress.org/plugins/tags/%1$s)', $tag );
					},
					$this->metadata['Tags']
				)
			);
		}
		if ( isset( $formatted_metadata['License URI'] ) && isset( $formatted_metadata['License'] ) ) {
			$formatted_metadata['License'] = sprintf( '[%s](%s)', $formatted_metadata['License'], $formatted_metadata['License URI'] );
		}
		unset( $formatted_metadata['License URI'] );
		if ( 'trunk' === $this->metadata['Stable tag'] ) {
			$formatted_metadata['Stable tag'] .= ' (master)';
		}

		// Render metadata
		$markdown  = "<!-- DO NOT EDIT THIS FILE; it is auto-generated from readme.txt -->\n";
		$markdown .= sprintf( "# %s\n", $this->title );
		$markdown .= "\n";
		if ( file_exists( $params['assets_dir'] . '/banner-1544x500.png' ) ) {
			$markdown .= "![Banner]({$params['assets_dir']}/banner-1544x500.png)";
			$markdown .= "\n";
		}
		$markdown .= sprintf( "%s\n", $this->short_description );
		$markdown .= "\n";
		foreach ( $formatted_metadata as $name => $value ) {
			$markdown .= sprintf( "**%s:** %s  \n", $name, $value );
		}

		// All of the supported badges.
		$badges = array(
			'travis_ci_pro_url',
			'travis_ci_url',
			'coveralls_url',
			'grunt_url',
			'david_url',
			'david_dev_url',
			'gemnasium_url',
			'gemnasium_dev_url',
			'gitter_url',
		);

		$badge_md = '';

		for ( $i = 0; $i < count( $badges ); $i++ ) {
			if ( isset( $params[ $badges[ $i ] ] ) ) {
				$badge = $badges[ $i ];
				$url = $params[ $badge ];
				if ( 'travis_ci_pro_url' === $badge ) {
					$badge_md .= sprintf( '[![Build Status](%1$s)](%2$s) ', $params['travis_ci_pro_badge_src'], $url );
				}
				if ( 'travis_ci_url' === $badge ) {
					$badge_md .= sprintf( '[![Build Status](%1$s.svg?branch=master)](%1$s) ', $url );
				}
				if ( 'coveralls_url' === $badge ) {
					$badge_md .= sprintf( '[![Coverage Status](%s)](%s) ', $params['coveralls_badge_src'], $url );
				}
				if ( 'grunt_url' === $badge ) {
					$badge_md .= sprintf( '[![Built with Grunt](https://cdn.%1$s/builtwith.png)](http://%1$s) ', $url );
				}
				if ( 'david_url' === $badge ) {
					$badge_md .= sprintf( '[![Dependency Status](%1$s.svg)](%1$s) ', $url );
				}
				if ( 'david_dev_url' === $badge ) {
					$badge_md .= sprintf( '[![devDependency Status](%1$s/dev-status.svg)](%1$s#info=devDependencies) ', $url );
				}
				if ( 'gemnasium_url' === $badge ) {
					$badge_md .= sprintf( '[![Dependency Status](%1$s)](%2$s) ', $params['gemnasium_badge_src'], $url );
				}
				if ( 'gemnasium_dev_url' === $badge ) {
					$badge_md .= sprintf( '[![devDependency Status](%1$s)](%2$s#development-dependencies) ', $params['gemnasium_dev_badge_src'], $url );
				}
				if ( 'gitter_url' === $badge ) {
					$badge_md .= sprintf( '[![Join the chat at %1$s](https://badges.gitter.im/Join Chat.svg)](%1$s) ', $url );
				}
			}
		}

		if ( ! empty( $badge_md ) ) {
			$markdown .= "\n";
			$markdown .= $badge_md;
			$markdown .= "\n";
		}

		$markdown .= "\n";

		foreach ( $this->sections as $section ) {
			$markdown .= sprintf( "## %s ##\n", $section['heading'] );
			$markdown .= "\n";

			$body = $section['body'];

			$body = call_user_func( $general_section_formatter, $body );
			if ( isset( $section_formatters[ $section['heading'] ] ) ) {
				$body = trim( call_user_func( $section_formatters[ $section['heading'] ], $body ) );
			}

			if ( $body ) {
				$markdown .= sprintf( "%s\n", $this->chomp( $body ) );
			}
			foreach ( $section['subsections'] as $subsection ) {
				$sub_body = $subsection['body'];
				$sub_body = call_user_func( $general_section_formatter, $sub_body );

				$markdown .= sprintf( "### %s ###\n", $subsection['heading'] );
				$markdown .= sprintf( "%s\n", $this->chomp( $sub_body ) );
				$markdown .= "\n";
			}

			$markdown .= "\n";
		}

		return $markdown;
	}

	/**
	 * Remove last newline. Props Perl.
	 *
	 * @param $string
	 *
	 * @return string
	 */
	function chomp( $string ) {
		return preg_replace( '/\n$/', '', $string );
	}
}
