#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Deterministic::Access' ) || print "Bail out!\n";
}

diag( "Testing Data::Deterministic::Access $Data::Deterministic::Access::VERSION, Perl $], $^X" );
