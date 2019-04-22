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
    isa      => 'URL',
    is       => 'rw',
    required => 0,
    default  => sub {Mojo::URL->new('/assets/generic_face.png')}
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

1;