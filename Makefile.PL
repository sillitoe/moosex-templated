use strict;
use warnings;
use inc::Module::Install;
use Module::Install::External;

name 'MooseX-Templated';
all_from 'lib/MooseX/Templated.pm';
license 'perl';

requires 'File::Slurp'              => '9999.13';
requires 'File::Where'              => '1.16';
requires 'Moose'                    => '1.0';
requires 'Readonly'                 => '1.03';
requires 'Template'                 => '2.20';
requires 'Path::Class'              => '0.16';

tests_recursive();

WriteAll();

if ($Module::Install::AUTHOR) {
        system('pod2text lib/MooseX/Templated.pm > README');
}
