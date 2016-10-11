use Test::More tests => 4;

use strict;
use warnings;
use FindBin;
use MooseX::Templated::Util qw/ where_pm /;

use lib "$FindBin::Bin/lib";

my $libdir = "$FindBin::Bin/lib";

{
  my ($abs_path, $inc_path, $require) = where_pm( 'Farm::Cow' );

  is( $abs_path, "$libdir/Farm/Cow.pm" );
  is( $inc_path, "$libdir" );
  is( $require, "Farm/Cow.pm" );
}

{
  my $abs_path = where_pm( 'Farm::Cow' );
  is( $abs_path, "$libdir/Farm/Cow.pm" );
}

1;
