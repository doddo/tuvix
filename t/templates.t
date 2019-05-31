#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw\create_testapp\;

my $templates_dir = "/assets/tuvix_templates.conf";

my $t = create_testapp($templates_dir);

cmp_ok($t->app->renderer->paths->[0], 'eq', 'assets/templates',
    "Templates dir from conf is set and takes precedence over internal templates dir");

$t->get_ok('/posts')
    ->status_is(200)
    ->content_like(
    qr{<h1 id='overridden_template'>This is just to test that the template have been overridden</h1>});

done_testing();