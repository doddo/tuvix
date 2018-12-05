package Tuvix::Controller::Posts;
use Mojo::Unicode::UTF8;

use Mojo::Base 'Mojolicious::Controller';
use Mojolicious;
use Mojo::Util qw/url_escape/;

use Tuvix::Model::Posts;

use strict;
use warnings FATAL => 'all';

sub get_posts {
    my $self = shift;
    my $page = $self->param('page') || 1;
    my $posts_per_page = $self->param('posts_per_page') || 10;

    $self->stash(
        page  => $page,
        posts => $self->posts->get_posts_from_query(undef, $page, $posts_per_page)
    );
    $self->render(
        template => 'post'
    )
}

sub get_posts_from_ymd_uri {
    my $self = shift;

    # TODO Fix
    my $uri = sprintf '/post/%s/%s', $self->param('ymd'), url_escape($self->param('uri'));

    $self->stash(
        page  => 1,
        posts => $self->posts->get_posts_from_query({ 'uri' => $uri })
    );
    $self->render(
        template => 'post'
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
