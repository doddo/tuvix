package Tuvix::Schema::ResultSet::Post;
use strict;
use warnings FATAL => 'all';
use DateTime;

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

    my $rs = return $self->search(
        { path => $path },
    );
    return $rs->next;
}

sub get_posts_from_month {
    my $self = shift;
    my $wanted_date_start = shift; #TODO assert DateTime

    my $wanted_date_end = DateTime
        ->last_day_of_month(year => $wanted_date_start->year, month => $wanted_date_start->month)
        ->add(days => 1)
        ->subtract(seconds => 1);

    my $dtf = $self
        ->result_source
        ->schema
        ->storage
        ->datetime_parser;

    my $rs = $self->search(
        { 'date' => {
            -between => [
                $dtf->format_datetime($wanted_date_start),
                $dtf->format_datetime($wanted_date_end)
            ] }
        },
        {
            order_by => { -desc => qw/date/ },
        }
    );
    return $rs;

}

sub get_recent_posts {
    return shift
        ->get_posts_from_query(undef, 1, 10);
}

sub get_latest {
    return shift
        ->get_posts_from_query(undef, 1, 1)
        ->next;
}

1;