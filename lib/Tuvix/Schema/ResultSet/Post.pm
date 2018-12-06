package Tuvix::Schema::ResultSet::Post;
use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class::ResultSet';

sub get_posts_from_query {
    my $self = shift;
    my $query = shift;
    my $page = shift || 1;
    my $limit = shift || 10;

    my $rs = $self->search(
        $query,
        {
            order_by => { -desc => qw/date/ },
            page     => $page,
            limit    => $limit
        }
    );
    return $rs;
}

1;