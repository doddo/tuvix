#!/usr/bin/env perl


BEGIN {unshift @INC, "$FindBin::Bin/../lib"}


use Data::GUID;
use Mojolicious::Lite;

use Plerd;
use Plerd::Util;

use Tuvix;
use Tuvix::Schema;

plugin 'Config' => { file => '../tuvix.conf' };
plugin 'DefaultHelpers';

use strict;
use warnings;

my $schema = Tuvix::Schema->connect(@{app->config('db')});

# $schema = Tuvix::Schema->connect("dbi:SQLite:/home/petter/plerd/db/tuvix.db","","")

$schema->deploy({ add_drop_table => 1 });

my $config_ref = app->config('plerd');

my $plerd = Plerd->new($config_ref);

for my $post (@{$plerd->posts}) {
    my $post = $schema->resultset('Post')->new({
        title       => $post->title(),
        guid        => $post->guid()->as_string,
        body        => $post->body(),
        date        => $post->date(),
        description => $post->description(),
        author_name => $post->plerd->author_name()
    });
    say $post->title();
    $post->insert or die $!;
}

my @all_posts = $schema->resultset('Post')->all;

1;