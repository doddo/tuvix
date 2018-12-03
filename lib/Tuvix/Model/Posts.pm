package Tuvix::Model::Posts;
use Mojo::Unicode::UTF8;
use Mojo::Base;
use Tuvix::Schema;
use DBIx::Class::ResultSet;

use Moose;

has 'db_conf' => (
    isa      => 'ArrayRef',
    is       => 'ro',
    required => 1
);

sub schema {
    my $self = shift;
    return Tuvix::Schema->connect(@{$self->db_conf},
        {
            RaiseError     => 1,
            sqlite_unicode => 1,
        }
    );
}




sub get_posts_from_query {
    my $self = shift;
    my $query = shift;
    my $page = shift || 1;
    my $limit = shift || 10;


    my $schema = $self->schema;

    my $rs = $schema->resultset('Post')->search(
        $query,
        {
            order_by => { -desc => qw/date/ },
            page     => $page,
            limit    => $limit
        }
    );
    return $rs
}

1;