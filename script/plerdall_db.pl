#!/usr/bin/env perl

BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use Mojo::Unicode::UTF8;
use Mojolicious::Lite;

use Plerd;
use Plerd::Util;

use Try::Tiny;
use Tuvix;
use Tuvix::PlerdHelper;
use Tuvix::Schema;

use feature qw/say/;

plugin 'Config' => { file => '../tuvix.conf' };
plugin 'DefaultHelpers';

use strict;
use warnings;

my $config_ref = app->config('plerd');

my $plerd = Plerd->new($config_ref);

my $ph = Tuvix::PlerdHelper->new(
    db      => \@{app->config('db')},
    db_opts => app->config('db_opts'),
    plerd   => $plerd
);

$ph->deploy_schema(1);

my $posts = $ph->publish_all;

while (my $post = $posts->next) {
    printf "%-50.48s %s\n", $post->title(), $post->path();
}

# TODO
#$_->process_webmentions() for @{$plerd{posts};

1;