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

my @posts = $posts->all;

foreach my $post (@posts){
    my $res = $webmention_transmitter->send_webmentions($post);
    ok ($$res{attempts} == 0, "No webmention attempts if no link is detected in the post body");

}

my $post_with_webmentions = shift(@posts);
my $webmention_target_uri = Mojo::URL->new($posts[0]->uri)->base($t->app->site_info->base_uri)->to_abs;
my $body = $post_with_webmentions->body();

$body .= sprintf "\n<p>Check <a href='%s'>this</a> out!!</p>", $webmention_target_uri;

$post_with_webmentions->body($body);

my $res = $webmention_transmitter->send_webmentions($post_with_webmentions);

ok ($$res{attempts} == 1, "One webmention attempt for inseted hyperlink [$webmention_target_uri] the post body");

done_testing();

