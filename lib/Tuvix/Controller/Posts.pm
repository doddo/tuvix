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
        posts => $posts,
        path  => $self->req->url->path
    );
    $self->render(
        template => $template,
        format => $format
    )
}

sub get_posts_from_path {
    my $self = shift;
    my $path = $self->param('postpath');
    my $posts = $self->posts->get_posts_from_query({ 'path' => $path });

    return $self->reply->not_found unless ($posts->count);

    $self->stash(
        page  => 1,
        posts => $posts
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
