package Tuvix::Model::SiteInfo;
use strict;
use warnings FATAL => 'all';

use Mojo::URL;

use Moose;
use Tuvix::TypeConstraints;

has 'base_uri' => (
    isa      => 'URL',
    is       => 'rw',
    required => 1,
    coerce   => 1
);

has 'title' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'author_email' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'author_name' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'author_photo' => (
    isa        => 'URL',
    is         => 'rw',
    required   => 0,
    coerce     => 1
);

has 'publication_path' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'send_webmentions' => (
    isa     => 'Int',
    is      => 'rw',
    default => 0,
);

has 'sidebar_section' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1
);

has 'footer_section' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1
);

has 'author_bio' => (
    isa     => 'Str',
    is      => 'ro',
    default => sub {""}
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = shift;
    my %args = %{$args};

    my $author_photo = Mojo::URL->new($args{'author_photo'} // '/assets/generic_face.png');

    $args{ author_photo } = $author_photo->is_abs
        ? $author_photo
        : Mojo::URL->new($args{'base_uri'})->path($author_photo);

    my @args = %args;
    return $class->$orig(@args);
};


sub _build_sidebar_section {
    my $self = shift;
    return <<EOM
  <section>
  <h1>Hello</h1>
  <p>
  This is a blog by <a href="mailto:${\($self->author_email)}">${\($self->author_name)}</a>.
  </section>
EOM
}

sub _build_footer_section {
    return <<EOM
   <p>Powered by <a href="https://github.com/doddo/tuvix">Tuvix</a> (powered by <a href="http://jmac.org/plerd">Plerd</a>).</p>
EOM
}

1;