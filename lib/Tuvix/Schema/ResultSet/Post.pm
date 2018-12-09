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

sub get_post_from_uri {
    my $self = shift;
    my $path = shift;

    my $rs = return  $self->search(
        { path => $path },
    );
    return $rs->next;
}

sub get_recent_posts {
    return shift->get_posts_from_query(undef, 1, 10);
}

1;