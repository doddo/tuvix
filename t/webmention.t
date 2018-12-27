#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use Web::Mention;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestData qw\create_testdb\;

my $dbh = create_testdb;

my $config = app->config;

my $t = Test::Mojo->new('Tuvix', $config);

$t->app->helper(posts => sub {
    Tuvix::Model::Posts->new(schema => $dbh)
});

# To get the webmention to say the full correct address
my $port = $t->get_ok('/')->tx->remote_port;

my $webmention_uri = Mojo::URL
    ->new('/webmention')
    ->base(Mojo::URL->new($t->app->site_info->webmention_uri->base->port($port)));

$t->get_ok('/posts')
    ->header_is(Link => sprintf '"<%s>; rel=\"webmention\"', $webmention_uri->to_abs);

done_testing();

