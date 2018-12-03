#!/usr/bin/env perl


BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use Try::Tiny;

use Data::GUID;
use Mojolicious::Lite;

use Plerd;
use Plerd::Util;

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
    my @ids = map {$_->guid()->as_string} @{$plerd->posts};

    # Delete all that is present already
    $schema->resultset('Post')->search(
        { guid => { -not_in => \@ids } }
    )->delete;


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
        try {
            $post->insert;
        } catch {
            $post->update;
        }
    }
};

my $rs;

try {
    $rs = $schema->txn_do($atomic_update);
}
catch {
    my $error = shift;
    # Transaction failed
    die "Could not perform transaxtion: $error ..."
};

1;