use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Templated',
    license             => 'perl',
    dist_author         => 'Ian Sillitoe <isillitoe@cpan.org>',
    dist_version_from   => 'lib/MooseX/Templated.pm',
    requires => {
        'Test::More' 	=> '0.86',
   		'File::Slurp'   => '9999.13',
   		'File::Where'   => '1.16',
   		'Moose' 		=> '0.60',
   		'Readonly' 		=> '1.03',
   		'Template'   	=> '2.20',
		'Path::Class'   => '0.16',
    },
    add_to_cleanup      => [ 'MooseX-Templated-*' ],
);

$builder->create_build_script();
