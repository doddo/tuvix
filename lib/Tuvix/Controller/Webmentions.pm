package Tuvix::Controller::Webmentions;
use Mojo::Unicode::UTF8;
use utf8;

use Mojo::Base 'Mojolicious::Controller';
use Mojolicious;
use Web::Mention::Mojo;
use URI::Split qw(uri_split uri_join);

use Try::Tiny;

use JSON;

my $json = JSON->new->convert_blessed;

sub process_webmention {
    my $c = shift;

    my $webmention;
    try {
        $webmention = Web::Mention::Mojo->new_from_request($c);
    }
    catch {
        $c->render(status => 400, text => "Malformed webmention: $_");
    };

    return unless $webmention;

    my $path = $webmention->target->path;

    if ($path->parts->[0] eq 'posts') {
        my $posts = $c->posts->get_posts_from_query({ 'path' => $path });

        if ($posts->count) {
            $c->render(status => 202, text => "👍The webmention has arrived and will be delt with in due time.");
            # TODO check so that the queue ain't too big usw.
            $c->app->minion->enqueue(receive_webmention => [ $json->encode($webmention) ]);
        }
        else {
            $c->render(
                status => 404,
                text   => sprintf("Target post [%s] not found.", $webmention->target->path)
            );
        }
    }
    else {
        $c->render(
            status => 404,
            text   => sprintf("Target not found.")
        );
    }
}



1;