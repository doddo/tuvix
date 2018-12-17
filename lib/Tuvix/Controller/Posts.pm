package Tuvix::Controller::Posts;
use Mojo::Unicode::UTF8;

use Mojo::Base 'Mojolicious::Controller';
use Mojolicious;
use Mojo::Util qw/url_escape/;

use Tuvix::Model::Posts;

use DateTime;

use strict;
use warnings FATAL => 'all';


sub get_posts {
    my $self = shift;
    my $page = $self->param('page') || 1;
    my $template = 'post';
    my $posts_per_page = $self->param('posts_per_page') || 10;
    my $format = 'html';

    if ($self->param('feed') && $self->param('feed') eq 'rss') {
        $posts_per_page = 100;
        $page = 1;
        $template = 'rss';
        $format = 'xml'
    }

    my $posts = $self->posts->get_posts_from_query(undef, $page, $posts_per_page);

    return $self->reply->not_found unless ($posts->count);

    $self->stash(
        page  => $page,
        title => $self->plerd->title,
        posts => $posts,
        path  => $self->req->url->path
    );
    $self->render(
        template => $template,
        format   => $format
    )
}

sub get_posts_from_path {
    my $self = shift;
    my $path = $self->param('postpath');
    my $posts = $self->posts->get_posts_from_query({ 'path' => $path });

    return $self->reply->not_found unless ($posts->count);

    $self->stash(
        page  => 1,
        title => sprintf("%s - %s ", ($posts->all)[0]->title, $self->plerd->title),
        posts => $posts
    );
    $self->render(
        template => 'post'
    )
}

sub get_archive {
    my $self = shift;
    my $year;
    my $month;
    my $dt = DateTime->now;
    my $time_zone = $self->config('time_zone') // DateTime::TimeZone->new(name => 'local');

    unless ($self->param('year') && $self->param('month')) {
        $year = $dt->year;
        $month = $dt->month;
    }
    else {
        $year = $self->param('year');
        $month = $self->param('month');

        unless ($year =~ m/^\d+$/ && ($year >= 1347 && $year <= $dt->year)) {
            $self->render(status => 401, text => "Invalid Year");
            return;
        }
        unless ($month =~ m/^\d+$/ && ($month >= 1 && $month <= $dt->month)) {
            $self->render(status => 401, text => "Invalid Month");
            return;
        }
    }


    my $wanted_date_start = DateTime->new(
        year      => $year,
        month     => $month,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => $time_zone,
    );

    my $posts = $self
        ->posts
        ->resultset
        ->get_posts_from_month($wanted_date_start);

    #return $self->reply->not_found unless ($posts->count);


    $self->stash(
        wanted => $wanted_date_start,
        title => 'Archive',
        posts => $posts,
    );
    $self->render(
        template => 'archive',
    )
}


sub load_next {
    my $self = shift;
    $self->on(message => sub {
        my ($self, $page) = @_;
        for my $post ($self->posts->get_posts_from_query(undef, $page)->all) {
            $self->stash(post => $post);
            $self->send($self->render_to_string(template => '_post'));
        };
    });
}

1;
