package MooseX::Templated::Role;

=head1 NAME

MooseX::Templated::Role - Role to render a Moose class with template

=head1 SYNOPSIS

Farm/Cow.pm

    package Farm::Cow;
    use Moose;
    with 'MooseX::Templated::Role';

    has 'spots'   => ( is => 'rw' );
    has 'hobbies' => ( is => 'rw', default => sub { ['mooing', 'chewing'] } );

    sub moo { "Moooooooo!" }

Farm/Cow.tt

    This cow has [% self.spots %] spots - it likes
    [% self.hobbies.join(" and ") %]. 
    [% self.moo %]!

Elsewhere on the Farm...

    my $cow = Farm::Cow->new( spots => '8' );
    
    $cow->render();
    
    # This cow has 8 spots - it likes
    # mooing and chewing.
    # Moooooooo!

=head2 Extended features

/alt/path/Farm/Cow.xml.tt2

    <cow sound="[% self.moo | html %]" spots="[% self.spots %]">
    
    [%- FOREACH hobby = self.hobbies %]
        <hobby name="[% hobby | html %]"/>
    [%- END %]
    
    </cow>

Then, back out on the farm

    $cow = Farm::Cow->new( spots => 8 );
    
    $cow->template_src_base( '/alt/path' );  # default is same as module
    $cow->template_src_ext ( '.tt2' );       # default is '.tt'

    $cow->render( 'xml' );                   # adds to file path

    # <cow sound="Moooooooo" spots="8">
    #    <hobby name="mooing"/>
    #    <hobby name="chewing"/>
    # </cow>

=cut

use Moose::Role;
use MooseX::Templated::View::TT;

use MooseX::Templated;
our $VERSION = $MooseX::Templated::VERSION; # CPAN complained when VERSION moved to MX::T

has 'template_view' => (
    is      => 'ro',
    does    => 'MooseX::Templated::View',
    lazy    => 1,
    handles => {
        template_src_ext  => 'template_src_ext',
        template_src_base => 'template_src_base',
    },
    default => sub { (shift)->_build_template_view() }
);

has 'template_view_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'MooseX::Templated::View::TT',
    required => 1,
);

has 'template_view_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

# implemented as sub (rather than handles) so it can be
# 'excluded' in consuming objects
sub render {
    my $self = shift;
    $self->template_view->render( @_ );
}

sub _build_template_view {
    my $self = shift;
    return $self->template_view_class->new(
            'module' => $self,
            'config' => $self->template_view_config,
        );
}

=head1 METHODS

=head2 render( %options )

This renders the module consuming this role and returns the output as a string. This
method accepts the following optional key/values (either as %options or \%options):

=head3 source

Specifies the template source to be used for the rendering process. For 
flexibility, the source can be specified in a number of different ways - the
intention is for it to Do What You Mean (DWYM).

How the source is interpreted will depend partly on the default options specified by the 
L<template_view_class> that you are using (the default view is L<MooseX::Templated::View::TT>).
However, for consistency across your application, the recommended usage is to allow the
template source to be decided by using 'shortcuts'.

Default:

    Farm::Cow->new->render()

    # CHECKS FOR:
    #   - Farm::Cow::_template()
    #   - /path/to/Farm/Cow.tt

Using shortcuts:

    Farm::Cow->new->render( source => 'xml' )
    
    # CHECKS FOR:
    #   - Farm::Cow::_template_xml()
    #   - /path/to/Farm/Cow.xml.tt

These alternatives will also work:

    Farm::Cow->new->render( source => '/other/path/cow.tt' );
    Farm::Cow->new->render( source => 'Cow goes [% self.moo %]' );

See L<Setting the template source> for more information on the logic behind 
choosing how to interpret this string.

=head2 template_view

Provides access to the underlying MooseX::Templated::View object

=head2 template_view_class

Can be passed in the constructor to specify which MooseX::Templated::View to use. 

By default this is set to use the view based on Template Toolkit:

    'template_view_class' => 'MooseX::Templated::View::TT'

However, it is entirely possible that views will be written for different templating 
engines in the future (contribs welcome!).

See L<MooseX::Templated::View> for details on implementing your own view.

=head2 template_view_config( \%options )

Config options to be passed to the template view class when creating the template
engine. These will be merged with any default parameters set by the view engine.

=cut


1; # Magic true value required at end of module
__END__

=head1 DESCRIPTION

=head2 Setting the template source

The decision process for assigning the source is indicated by first 
successful step in the sequence below:

=head2 render( source => "SCALAR" )

=over 8

=item 1. Internal method (shortcut)

Check if the calling module provides a method named '_template' or '_template_{TYPE}'.
If so, the template source will be set from the result of that method call.

    package Farm::Cow;
    
    with 'MooseX::Templated::Role';
    
    has 'spots'    => ( is => 'rw', default => 8 );
    has 'hobbies'  => ( is => 'rw', default => sub { [ 'mooing', 'chewing' ] } );
    
    sub _template { 'Cow has [% self.spots %] spots' }
    
    sub _template_xml {
        my $self = shift;
        return <<"_XML";
    <cow spots='[% self.spots %]'>
        [% FOREACH hobby = self.hobbies %]
        <hobby name="[% hobby %]" />
        [% END %]
    </cow>
    _XML
    };
    
    1;
    
    package main;
    
    print Farm::Cow->new->render;
    # 'Cow has 8 spots'
    
    print Farm::Cow->new->render( source => 'XML' );
    # <cow spots="8">
    #   <hobby name="mooing"/>
    #   <hobby name="chewing"/>
    # </cow>

=item 2. External file (shortcut)

Use an associated template file if it exists (see L<build_build_src_path> for more 
information on how the template file path is built). This is the recommended approach
as it separates the template location and content from the application code.

/path/to/lib/Farm/Cow.pm
    
    package Farm::Cow;
    
    with 'MooseX::Templated::Role';
    
    has 'spots'    => ( is => 'rw', default => 8 );
    has 'hobbies'  => ( is => 'rw', default => sub { [ 'mooing', 'chewing' ] } );
    
/path/to/lib/Farm/Cow.tt
    
    Cow has [% self.spots %] spots
    
/path/to/lib/Farm/Cow.xml.tt
    
    <cow spots="[% self.spots %]">
        [% FOREACH hobby = self.hobbies %]
        <hobby name="[% hobby %]" />
        [% END %]
    </cow>
    
Elsewhere...
    
    use Farm::Cow;
    
    print Farm::Cow->new->render;
    # 'Cow has 8 spots'
    
    print Farm::Cow->new->render( source => 'XML' );
    # <cow spots="8">
    #   <hobby name="mooing"/>
    #   <hobby name="chewing"/>
    # </cow>


=item 3. External file

Treats the string as a path to the template source file. This is not the recommended approach 
as liberally scattering hardcoded file paths into your application code is most probably a
bad idea.

    Farm::Cow->new->render( source => '/path/to/lib/Farm/Cow.tt' );
    # 'Cow has 2 spots'

=back

=head2 render( source => \"SCALAR" )

Alternatively, if you pass the source as a SCALAR REF then it will be 
assumed to be raw template source. This is not a recommended approach, 
but hey - TMTOWTDI.

    Farm::Cow->new->render( source => \'Cow goes "[% self.moo %]"!' );
    # 'Cow goes "Moooooooo!"'


=head1 DEPENDENCIES

L<Moose>, L<Template>, L<Readonly>, L<File::Slurp>, L<File::Where>

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
