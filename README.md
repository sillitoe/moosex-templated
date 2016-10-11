# NAME

MooseX::Templated - template-based rendering of Moose objects

# SYNOPSIS

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

# DESCRIPTION

The `MooseX::Templated` role provides the consuming class with a method
`render()` which allows template-based rendering of the object.

# METHODS

The following methods are provided to the consuming class:

## template\_engine

Accessor for an instance of the templating engine responsible for rendering
the template

## render

Finds the template source, performs the rendering, returns
the rendered result as a string.

Note: the location of the template source is affected by (optional) arguments
and role configuration (see below for details).

## TEMPLATE SOURCE

On calling `render`, the template engine will look for the template source in a
few different locations: files, methods, inline.

    Farm::Cow->new()->render()

### file

This will look for a template file that relates to the calling package. With
default settings, the above example would look for:

    __LIB__/Farm/Cow.tt

Where `__LIB__` is the root directory for the modules.

The file path can be affected by configuration options: `template_root`,
`template_suffix`

### method `_template`

Define a local method within the calling package which returns the template
source as a string. With default settings, this will look for the method
`"_template"`, e.g.

    sub Farm::Cow::_template { ... }

The expected method name is affected by configuration option: `template_method_stub`.

### inline

Provide the template source directly to the render function (as a reference
to the template string).

    Farm::Cow->render( \"Cow goes [% self.moo %]!" );

# CONFIGURATION

Defaults about how to find your template files / methods can be provided at
role composition, e.g.

    with 'MooseX::Templated' => {
      template_suffix => '.tt2',
      template_root   => '__LIB__/../root',
    };

## template\_suffix

default: ".tt"

## template\_root

default: "\_\_LIB\_\_"

## template\_method\_stub

default: "\_template"

## view\_class

default: "MooseX::Templated::View::TT"

See [MooseX::Templated::Engine](https://metacpan.org/pod/MooseX::Templated::Engine) and [MooseX::Templated::View](https://metacpan.org/pod/MooseX::Templated::View) for more information

# DISCUSSION

## What this module aims to be

The intention of this module is to provide a quick and simple framework
to glue all things good about Moose to all things sensible about using
templates (i.e. separate your internals from your display logic).

It makes some guesses about what your templates are called and where
they live. Going along with those defaults should get you up and
running within a couple lines of code.

If you don't want to go with those default suggestions then there should be
enough flexibility to fit your setup with the minimum of fuss
(patches/suggestions are always welcome).

## What this module doesn't aim to be

This module is not intended to be a replacement for the kind of heavy
lifting that a real MVC framework should be doing.

If you are considering using this for web based rendering then I would
strongly suggest looking at [Catalyst](https://metacpan.org/pod/Catalyst), [Dancer2](https://metacpan.org/pod/Dancer2), [Mojolicious](https://metacpan.org/pod/Mojolicious), etc.

# SEE ALSO

[Moose](https://metacpan.org/pod/Moose)

Please report any bugs or feature requests to
`bug-moosex-templated@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org).

# ACKNOWLEDGEMENTS

Chris Prather (perigrin)

# AUTHOR

Ian Sillitoe  `<isillitoe@cpan.org>`

# LICENCE AND COPYRIGHT

Copyright (c) 2008, Ian Sillitoe `<isillitoe@cpan.org>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
