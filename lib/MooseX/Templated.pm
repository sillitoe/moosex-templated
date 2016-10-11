package MooseX::Templated;

use MooseX::Role::Parameterized;
use MooseX::Templated::Engine;
use MooseX::Types::Path::Class qw/ Dir /;
use Path::Class;
use namespace::autoclean;

our $VERSION = '0.05';

parameter view_class => (
  is => 'ro',
  isa => 'Str',
  default => 'MooseX::Templated::View::TT',
);

parameter template_method_stub => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_template_method_stub',
);

parameter template_suffix => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_template_suffix',
);

parameter template_root => (
  is => 'ro',
  isa => Dir,
  coerce => 1,
  predicate => 'has_template_root',
);

role {
  my $p = shift;

  has 'template_engine' => ( # class_has ?
    is => 'ro',
    isa => 'MooseX::Templated::Engine',
    lazy => 1,
    builder => '_build_template_engine',
  );

  method "_build_template_engine" => sub {
    my $self = shift;
    my $engine = MooseX::Templated::Engine->new(
      ( $p->has_template_method_stub ? ( template_method_stub => $p->template_method_stub ) : () ),
      ( $p->has_template_suffix      ? ( template_suffix      => $p->template_suffix ) : () ),
      ( $p->has_template_root        ? ( template_root        => $p->template_root ) : () ),
      view_class           => $p->view_class,
      model                => $self,
    );
    return $engine;
  };

  method "render" => sub {
    my $self = shift;
    return $self->template_engine->render( @_ );
  };

};


1;

__END__

=head1 NAME

MooseX::Templated - template-based rendering of Moose objects

=head1 SYNOPSIS

    package Farm::Cow;

    use Moose;

    with 'MooseX::Templated';

    has 'spots'   => ( is => 'rw' );
    has 'hobbies' => ( is => 'rw', default => sub { ['mooing', 'chewing'] } );

    sub make_a_happy_noise { "Mooooooo" }

Specify template:

    sub _template { <<'_TT2' }

    This cow has [% self.spots %] spots - it likes
    [% self.hobbies.join(" and ") %].
    [% self.make_a_happy_noise %]!

    _TT2

Render the object:

    $cow = Farm::Cow->new( spots => '8' );

    print $cow->render();

    # This cow has 8 spots - it likes
    # mooing and chewing.
    # Mooooooo!

Specify the template in a separate file (rather than a local method)

    # lib/Farm/Cow.tt

Change default file location (and other options):

    # lib/Farm/Cow.pm

    with 'MooseX::Templated' => {
      template_suffix => '.tt2',
      template_root   => '__LIB__/../root',
    };

    # root/Farm/Cow.tt2

=head1 DESCRIPTION

The C<MooseX::Templated> role provides the consuming class with a method
C<render()> which allows template-based rendering of the object.

=head1 METHODS

The following methods are provided to the consuming class:

=head2 template_engine

Accessor for an instance of the templating engine responsible for rendering
the template

=head2 render

Finds the template source, performs the rendering, returns
the rendered result as a string.

Note: the location of the template source is affected by (optional) arguments
and role configuration (see below for details).

=head2 TEMPLATE SOURCE

On calling C<render>, the template engine will look for the template source in a
few different locations: files, methods, inline.

  Farm::Cow->new()->render()

=head3 file

This will look for a template file that relates to the calling package. With
default settings, the above example would look for:

  __LIB__/Farm/Cow.tt

Where C<__LIB__> is the root directory for the modules.

The file path can be affected by configuration options: C<template_root>,
C<template_suffix>

=head3 method C<_template>

Define a local method within the calling package which returns the template
source as a string. With default settings, this will look for the method
C<"_template">, e.g.

  sub Farm::Cow::_template { ... }

The expected method name is affected by configuration option: C<template_method_stub>.

=head3 inline

Provide the template source directly to the render function (as a reference
to the template string).

  Farm::Cow->render( \"Cow goes [% self.moo %]!" );

=head1 CONFIGURATION

Defaults about how to find your template files / methods can be provided at
role composition, e.g.

  with 'MooseX::Templated' => {
    template_suffix => '.tt2',
    template_root   => '__LIB__/../root',
  };

=head2 template_suffix

default: ".tt"

=head2 template_root

default: "__LIB__"

=head2 template_method_stub

default: "_template"

=head2 view_class

default: "MooseX::Templated::View::TT"

See L<MooseX::Templated::Engine> and L<MooseX::Templated::View> for more information

=head1 DISCUSSION

=head2 What this module aims to be

The intention of this module is to provide a quick and simple framework
to glue all things good about Moose to all things sensible about using
templates (i.e. separate your internals from your display logic).

It makes some guesses about what your templates are called and where
they live. Going along with those defaults should get you up and
running within a couple lines of code.

If you don't want to go with those default suggestions then there should be
enough flexibility to fit your setup with the minimum of fuss
(patches/suggestions are always welcome).

=head2 What this module doesn't aim to be

This module is not intended to be a replacement for the kind of heavy
lifting that a real MVC framework should be doing.

If you are considering using this for web based rendering then I would
strongly suggest looking at L<Catalyst>, L<Dancer2>, L<Mojolicious>, etc.

=head1 SEE ALSO

L<Moose>

=head1 REPOSITORY

L<https://github.com/sillitoe/moosex-templated>

=head1 ACKNOWLEDGEMENTS

Chris Prather (perigrin)

=head1 AUTHOR

Ian Sillitoe  C<< <isillitoe@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Ian Sillitoe C<< <isillitoe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
