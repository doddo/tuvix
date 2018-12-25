package Tuvix::Model::Posts;
use Mojo::Unicode::UTF8;
use Mojo::Base;
use Tuvix::Schema;
use DBIx::Class::ResultSet;
use Carp;
use Moose;

# TODO Deprecate this package.

has 'db' => (
    isa      => 'ArrayRef',
    is       => 'ro',
    required => 0
);

has 'db_opts' => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub {{}}
);

has 'schema' => (
    is         => 'rw',
    isa        => 'DBIx::Class::Schema',
    lazy_build => 1
);

sub BUILD {
    my $self = shift;
    if (!defined $self->schema && !defined($self->db)) {
        croak "Posts model needs either a db schema OR a 'db' connect string,",
         "but got none of those things\n";
    }
}

sub resultset {
    my $self = shift;
    return $self->schema->resultset('Post');
}

sub get_posts_from_query {
    my $self = shift;

    return $self->schema->resultset('Post')->get_posts_from_query(@_);
}

sub get_recent_posts {
    return shift->schema->resultset('Post')->get_recent_posts;
}

sub _build_schema {
    my $self = shift;
    return Tuvix::Schema->connect(@{$self->db}, $self->db_opts);
}


1;