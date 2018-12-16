package Tuvix::Model::BlogInfo;
use strict;
use warnings FATAL => 'all';

use Mojo::URL;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'URL'
    => as 'Object'
    => where {$_->isa('Mojo::URL')};

coerce 'URL'
    => from 'Str'
    => via {Mojo::URL->new($_)};

has 'base_uri' => (
    isa      => 'URL',
    is       => 'ro',
    required => 1,
    coerce   => 1
);

has 'websocket_uri' => (
    isa        => 'Str',
    is         => 'rw',
    required   => 0,
    lazy_build => 1
);

has 'webmention_uri' => (
    isa        => 'URL',
    is         => 'rw',
    required   => 0,
    lazy_build => 1
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

has 'publication_path' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

sub _build_websocket_uri {
    # TODO: Fix this
    my $self = shift;
    my $uri = $self->base_uri;
    $uri =~ s|^https|ws|;
    $uri =~ s|/*$|/more_posts|;
    return $uri;
}

sub _build_webmention_uri {
    my $self = shift;
    return Mojo::URL->new("/webmention")->base(Mojo::URL->new($self->base_uri))->to_abs;
}


1;