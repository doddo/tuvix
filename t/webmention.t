#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use Tuvix::WebmentionTransmitter;

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

my $webmention_transmitter = Tuvix::WebmentionTransmitter->new(base_uri => $t->app->site_info->base_uri);

my $posts = $dbh->resultset('Post');

while (my $post = $posts->next){
    my $res = $webmention_transmitter->send_webmentions($post);
    ok ($$res{attempts} == 0, "No webmention attempts if no link is detected in the post body");
}


done_testing();

