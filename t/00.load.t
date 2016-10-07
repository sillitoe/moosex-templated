use Test::More tests => 3;

BEGIN {
use_ok( 'MooseX::Templated' );
use_ok( 'MooseX::Templated::Role' );
use_ok( 'MooseX::Templated::View' );
}

diag( "Testing MooseX::Templated $MooseX::Templated::VERSION" );
