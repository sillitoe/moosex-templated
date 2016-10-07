use Test::More tests => 9;

use strict;
use warnings;
use FindBin;
use File::Spec::Functions;

use lib $FindBin::Bin . '/lib';

my @methods = qw(
    template_view
    template_view_class
    template_view_config
    template_src_ext
    template_src_base
    render
);

use_ok( 'Farm::Cow' );

isa_ok( my $cow = Farm::Cow->new( spots => 8 ), 'Farm::Cow' );

can_ok( $cow, @methods );

is( $cow->render, "This cow has 8 spots and goes Moooooooo!\n",
    'default render' );

isa_ok( $cow->template_view, 'MooseX::Templated::View::TT', 'template view' );

is( $cow->template_view_class, 'MooseX::Templated::View::TT', 'template view class' );

is_deeply( $cow->template_view_config, {}, 'template view config' );

is( $cow->template_src_ext, '.tt', 'template source ext' );

is( $cow->template_src_base, catfile( $FindBin::Bin, 'lib' ), 'template source base' );

