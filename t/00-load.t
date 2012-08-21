#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::TW' ) || print "Bail out!\n";
}

diag( "Testing Win32::TW $Win32::TW::VERSION, Perl $], $^X" );
