#!/usr/bin/env perl


BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use Data::GUID;

use Mojo::Unicode::UTF8;
use Mojo::Util qw(url_escape);
use Mojolicious::Lite;

use Plerd;
use Plerd::Util;

use Try::Tiny;
use Tuvix;
use Tuvix::Schema;

use feature qw/say/;

plugin 'Config' => { file => '../tuvix.conf' };
plugin 'DefaultHelpers';

use strict;
use warnings;

my $schema = Tuvix::Schema->connect(
    @{app->config('db')}, app->config('db_opts'));

$schema->deploy({ add_drop_table => 0 });

my $config_ref = app->config('plerd');

my $plerd = Plerd->new($config_ref);

my $atomic_update = sub {
    my @ids = map {$_->guid()->as_string => $_} @{$plerd->posts};

    # Delete all that is present already
    $schema->resultset('Post')->search(
        { guid => { -not_in => \@ids } }
    )->delete;

    # while (my $post = $schema->resultset('Post')->next) {

    for my $plerd_post (@{$plerd->posts}) {
        my $post = $schema->resultset('Post')->find_or_new(
            { guid => $plerd_post->guid() },
        );

        $post->title($plerd_post->title());
        $post->body($plerd_post->body());
        $post->date($plerd_post->date());
        $post->description($plerd_post->description());
        $post->author_name($plerd_post->plerd->author_name());

        unless ($post->uri()) {
            # Find a name which is not allocated already ...
            my $uri_base = join '/', ('/post', $post->date->ymd, url_escape($plerd_post->title));
            my $uri = $uri_base;
            my $i = 0;
            while ($schema->resultset('Post')->find({ uri => $uri })) {
                $uri = sprintf '%s-%i', $uri_base, $i++
            }
            $post->uri($uri);

        }
        # Save this here so we cam send properly formatted webmentions
        $plerd_post->published_filename($post->uri());

        printf "%-50.48s %s\n", $post->title(), $post->uri();

        $post->update_or_insert;
    }
};

my $rs;

try {
    $rs = $schema->txn_do($atomic_update);
}
catch {
    my $error = shift;
    # Transaction failed
    die "Could not perform transaction: $error ..."
};

# TODO:
# Tell plerdall_db to send webmentions if applicable

1;