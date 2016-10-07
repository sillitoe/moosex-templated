package MooseX::Templated::View;

=head1 NAME

MooseX::Templated::View - Interface for MooseX::Templated views

=head1 SYNOPSIS

    package MooseX::Templated::View::SomeRenderer;
    
    use Moose;
    use Some::Renderer;
    
    with 'MooseX::Templated::View';
    
    # engine class
    has '+engine_class'     => ( default => 'Some::Renderer' );

    # default config to pass to engine constructor
    has '+engine_config'    => ( default => sub { { OPTION => 1 } } );

    # default file extension to use
    has '+template_src_ext' => ( default => '.ext' );
    
    # return rendered output as string
    sub process {
        my $self        = shift;

        # instantiated from engine_class and engine_config
        my $engine      = $self->engine; 

        # source set by framework defaults
        my $source      = $self->source;
        
        # implemented by engine
        my $output = $engine->some_render_method( 
                        src   => $source, 
                        stash => { self => $self },
                    );

        return $output;
    }

/path/to/Farm/Chicken.pm

    package Farm::Chicken;
    use Moose;
    with 'MooseX::Templated::Role';

    has 'feathers' => ( is => 'rw' );

/path/to/Farm/Chicken.ext

    This chicken has <<self.feathers>> feathers

Elsewhere...

    $chicken = Farm::Chicken->new( 
            feathers             => 57,
            template_view_class  => 'MooseX::Templated::View::SomeRenderer',
        );

    $chicken->render(); # This chicken has 57 feathers

=cut

use Moose::Role;
use Moose::Util::TypeConstraints;

use Carp;
use Readonly;
use FileHandle;
use File::Slurp qw( read_file );
use File::Where qw( where_pm );
use Path::Class::File;

Readonly my $TEMPLATED_SOURCE_METHOD_STUB => '_template';

subtype 'TemplateSource'
    => as 'Str';

has 'engine' => (
    isa     => 'Object',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_engine',
);

has 'engine_class' => (
    isa      => 'ClassName',
    is       => 'ro',
    required => 1
);


has 'module' => (          # maybe I should weaken this?
    isa      => 'Object',
    is       => 'ro',
    required => 1
);

has 'source' => (
    isa      => 'TemplateSource',
    reader   => 'get_source',
    default  => sub { (shift)->set_source },
    lazy     => 1,
);

has 'engine_config' => ( 
    is      => 'rw',
    isa     => 'HashRef',
);

has 'template_src_base' => ( 
    is => 'rw', 
    isa => 'Str',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my ( $abs_file, $inc_path, $rel_dir ) 
            = where_pm( blessed ( $self->module ) );

        #warn "abs_file: $abs_file";
        #warn "inc_path: $inc_path";
        #warn "rel_dir: $rel_dir";

        return $inc_path;
    }
);

has 'template_src_ext' => ( 
    is => 'rw', 
    isa => 'Str' 
);

=head1 ATTRIBUTES

=head2 engine

Instance of the templating engine used for the render

=head2 engine_class <required>

The class name of template engine object

This is used to instantiate the new 

=head2 engine_config( \%options )

Configuration options to pass to the Template engine constructor

=head2 module <required>

This is a reference to the object we are rendering - i.e. the object consuming the MooseX::Templated::Role

=head2 source

This is the template source string

=head2 template_src_base

Where to start looking for associated template files. If this evaluates to 
false then it will assume the template file resides alongside the module (with
a different extension depending on the particular view).

  Farm::Cow.pm

  template_src_base => ''               # /usr/lib/perl5/[...]/Farm/Cow.tt
  template_src_base => '/etc/tt2/src'   # /etc/tt2/src/Farm/Cow.tt

=head2 template_src_ext

Extension to use when searching for the template_src, e.g. '.tt'

=head1 INTERFACE

=head2 render( \%options )

This sets up the generic environment for the render (e.g. template source and stash vars)
then calls the process method on the implementing view.

=head3 options

=over 8

=item source

Sets the template source to something other than the default

See L<source>

=item stash

Provides additional key/value data to be available in the template source

=back

=cut

sub render {
    my $self    = shift;
    my $args    = @_ == 1 ? { source => $_[0] } : { @_ };
    
    croak "! Error: expected optional HASH (or HASH REF) in call to render() ($args)"
        unless ref $args eq 'HASH';

    $self->set_source( $args->{ source } );
    
    croak "! Error: sorry, stash not yet implemented"
        if $args->{ stash };
    
#     use Data::Dumper;
#     warn "self: $self";
#     warn "args: ".Dumper( $args );
#     warn "source: ".$self->get_source;
    
    return $self->process();
}

=head2 process

The individual view implements this method to actually process the template.

=cut

requires 'process';

=head2 set_source( $shortcut | $filename | \"raw template source" )

Template source code used to process the template - will return the first successful
step from the following:

=head3 source => SCALAR

=over 8

=item 1. Internal method shortcut

=item 2. External file shortcut

=item 3. File path

=back

e.g. for MooseX::Templated::View::TT
    
    source => ''    # Farm::Cow::_template()
                    # /path/to/Farm/Cow.tt
    
    source => 'XML' # Farm::Cow::_template_xml()
                    # /path/to/Farm/Cow.xml.tt

    source => 'file.tt'

=head3 SCALAR REF

=over 8

=item Raw template source string
    
    source => \'[% self.blah %]'

=back

=cut

sub set_source {
    my $self            = shift;
    my $source_type     = shift || '';    
    
    if ( ref $source_type eq 'SCALAR' ) {
        return $self->{ source } = ${ $source_type };
    }
    
    my $source_type_lc  = lc( $source_type );
    
    my $method = 
            $source_type
            ? $TEMPLATED_SOURCE_METHOD_STUB . "_" . $source_type_lc # _template_xml()
            : $TEMPLATED_SOURCE_METHOD_STUB;                        # _template()
    
    my $file_ext = 
            $source_type
            ? "." . $source_type_lc . $self->template_src_ext       # .xml.tt
            : $self->template_src_ext;                              # .tt

    my $default_file = $self->build_src_path( ext => $file_ext );

    my $source =   $self->module->can( $method ) ? $self->module->$method()
                 : -e $default_file              ? read_file( $default_file )
                 : -e $source_type               ? read_file( $source_type )
                 : undef;
    
    if ( not defined $source ) {
        croak "[error] ".__PACKAGE__.": couldn't set source:\n".
            ( ($source_type =~ /\n/xms) 
                ? ' - looks like you passed source as "SCALAR" (try \"SCALAR")'."\n"
                : ( 
                    " - tried the following tests:\n".
                    join( "", map { "    $_\n" }
                        "METHOD: ".blessed( $self->module ) . "::" . $method,
                        "FILE:   ".$default_file,
                        "FILE:   ".$source_type,
                    ) .
                    ' - maybe you passed the source as "SCALAR" (try \"SCALAR")'."\n"
                )
            );
    }
    
    return ( $self->{ source } = $source );
}

=head2 build_src_path( \%options )

Builds the default filename to be used the template source

    Farm::Cow => /path/to/Farm/Cow.tt
    
    template_src_base  class_name    template_src_ext
    /path/to/          Farm/Cow      .tt

=head3 options

Explicitly passed options override defaults

=over 8 

=item 'base' => '/alt/path'

=item 'ext' => '.ext'

=back

=cut

sub build_src_path {
    my $self        = shift;
    my $args        = @_ == 1 ? $_[0] : { @_ };
    
    my ($abs_file, $inc_path, $require) 
                    = where_pm( blessed $self->module );

    my $base        = $args->{ base }
                        || $self->template_src_base;
    
    my $ext         = $args->{ ext }
                        || $self->template_src_ext;

    my $path = Path::Class::File->new( $base, $require ) . "";

    $path    =~ s{ .pm $ }{$ext}xms;
    
    return $path;
}

sub _build_engine {
    my $self = shift;
    return $self->engine_class->new( $self->engine_config );
}


1; # Magic true value required at end of module
__END__


=head1 DESCRIPTION

This is an interface that allows the front-end MooseX::Templated::Role
to speak to the specific back-end template engines (e.g. MooseX::Templated::View::TT).
It also provides generic functionality for all MooseX::Templated::View:: modules.

=head1 DEPENDENCIES

Readonly, File::Slurp, File::Where, Path::Class::File

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
