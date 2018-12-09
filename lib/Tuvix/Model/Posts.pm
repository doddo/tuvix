package Tuvix::Model::Posts;
use Mojo::Unicode::UTF8;
use Mojo::Base;
use Tuvix::Schema;
use DBIx::Class::ResultSet;

use Moose;

has 'db' => (
    isa      => 'ArrayRef',
    is       => 'ro',
    required => 1
);

has 'db_opts' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1
);

sub schema {
    my $self = shift;
    return Tuvix::Schema->connect(@{$self->db}, $self->db_opts);
}

sub get_posts_from_query {
    my $self = shift;

    return $self->schema->resultset('Post')->get_posts_from_query(@_);
}

sub get_recent_posts {
    return shift->schema->resultset('Post')->get_recent_posts;
}

1;