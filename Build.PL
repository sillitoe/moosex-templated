use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Templated',
    license             => 'perl',
    dist_author         => 'Ian Sillitoe <isillitoe@cpan.org>',
    dist_version_from   => 'lib/MooseX/Templated.pm',
    requires => {
      'Test::More' 	    => '0.86',
   		'Moose'           => '2.0',
      'MooseX::Role::Parameterized' => '0.60',
      'MooseX::Types::Path::Class' => '',
      'namespace::autoclean' => '',
   	  'Template'   	    => '2.20',
	    'Path::Class'     => '0.16',
    },
    add_to_cleanup      => [ 'MooseX-Templated-*' ],
);

$builder->create_build_script();
