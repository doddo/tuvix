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
    ->base(Mojo::URL->new($t->app->site_info->base_uri->port($port)));

$t->app->helper(webmention_url => sub {
   Mojo::URL
    ->new('/webmention')
    ->base(Mojo::URL->new($t->app->site_info->base_uri->port($port)));
});

$t->get_ok('/posts')
    ->header_is(Link => sprintf '"<%s>; rel=\"webmention\"', $webmention_uri->to_abs);

my $webmention_transmitter = Tuvix::WebmentionTransmitter->new(base_uri => $t->app->site_info->base_uri->port($port));

my $posts = $dbh->resultset('Post');

my @posts = $posts->all;

foreach my $post (@posts) {
    my $res = $webmention_transmitter->send_webmentions($post);
    ok($$res{attempts} == 0, "No webmention attempts if no link is detected in the post body");

}

my $post_with_webmentions = shift(@posts);
my $webmention_target_uri = Mojo::URL->new($posts[0]->uri)->base($t->app->site_info->base_uri->port($port))->to_abs;
my $body = $post_with_webmentions->body();

$body .= sprintf "\n<p>Check <a href='%s'>this</a> out!!</p>", $webmention_target_uri;

$post_with_webmentions->body($body);

$post_with_webmentions->update();
$t->get_ok('/');

my @webmentions = $webmention_transmitter->get_webmentions_from_post($post_with_webmentions);

ok(@webmentions == 1, 'Correct amount of one (1) webmention created');

my $payload;
foreach my $webmention (@webmentions) {
    isa_ok($webmention, 'Web::Mention', 'output from WebmentionTransmitter::get');
    isa_ok($webmention, 'Web::Mention::Mojo', 'output from WebmentionTransmitter::get');

    $webmention->ua($t->ua);
    $payload = $webmention->TO_JSON();

    cmp_ok($webmention->source, 'eq',
        Mojo::URL->new($t->app->site_info->base_uri)->port($port)->path(sprintf '/posts/%s', $post_with_webmentions->path),
        'Path of created webmention matches origin post');

    ok($webmention->verify, 'Webmention is verified OK');

    cmp_ok($webmention->author->name, 'eq', $post_with_webmentions->author_name(), 'Author of webmention is OK');

    #TODO: {
    #    local $TODO = "Fix so that the webmentions can use the Mojo-ua";
    #    ok($webmention->send);
    #};
}

done_testing();

