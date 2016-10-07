package MooseX::Templated::View::TT;

=head1 NAME

MooseX::Templated::View::TT - Template Toolkit View for MooseX::Templated

=head1 SYNOPSIS

See L<MooseX::Templated::View>

=cut

use Moose;

use Template;
use Carp;
use Readonly;

with 'MooseX::Templated::View';

Readonly my %TT_DEFAULT_CONFIG => (
    'ABSOLUTE' => 1,        # required for using default module name
);

=head2 template_src_ext

Default extension for Template files

    '.tt'

=cut

has '+template_src_ext' => ( default => '.tt' );

=head2 engine_class

    Template

See L<Template>

=cut

has '+engine_class'     => ( default => 'Template' );

=head2 engine_config

Default configuration for Template instance

    'ABSOLUTE' => 1

=cut

has '+engine_config'    => ( default => sub { \%TT_DEFAULT_CONFIG } );


has '+engine' => ( handles => [
        'error'
    ] );

sub BUILD {
    my $self = shift;
    $self->set_stash_key( 'self', $self->module );
}

=head2 stash

This is the key/value stash that will be passed to the template engine

=head2 set_stash_key( 'key', 'value' )

    stash => { 'key' => 'value' }

=head2 get_stash_key( 'key' )

    # returns 'value'

=head2 empty_stash( )

    stash => {}

=head2 delete_stash_key( 'key' )

    # deletes entry for key

=cut

has 'stash' => (
    'traits'    => [ 'Hash' ],
    'isa'       => 'HashRef',
    'is'        => 'rw',
    'handles'   => {
        set_stash_key    => 'set',
        get_stash_key    => 'get',
        delete_stash_key => 'delete',
        stash_keys       => 'keys',
    },
    'default' => sub { {} },
);


=head2 process( [ \%stash_vars ]  )

Processes the TT file and returns the output as a string

=cut

sub process {
    my $self        = shift;
    my $tt_output   = '';
    my $src         = $self->get_source;
    
    $self->engine->process( \$src, $self->stash, \$tt_output )
        or croak( "couldn't process template (module: ".( blessed $self->module ).")\n".
                  "\t".$self->error() );

    return $tt_output;
}

1; # Magic true value required at end of module
__END__


=head1 DEPENDENCIES

L<Template>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-moosex-templated@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Chris Prather (perigrin)

=head1 AUTHOR

Ian Sillitoe  C<< <isillitoe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Ian Sillitoe C<< <isillitoe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
