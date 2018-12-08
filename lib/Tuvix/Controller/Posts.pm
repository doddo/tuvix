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

    my $posts =  $self->posts->get_posts_from_query(undef, $page, $posts_per_page);

    $self->stash(
        page  => $page,
        posts => $posts
    );
    $self->render(
        template => 'post'
    )
}

sub get_posts_from_path {
    my $self = shift;
    my $path = $self->param('postpath');
    my $posts = $self->posts->get_posts_from_query({ 'path' => $path });

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
