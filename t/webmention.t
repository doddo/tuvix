#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use Tuvix::Model::Webmentions;

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
    ->header_is(Link => sprintf '<%s>; rel="webmention"', $webmention_uri->to_abs);

$t->post_ok('/webmention')
    ->status_is(400);

my $webmention_mgr = Tuvix::Model::Webmentions->new(base_uri => $t->app->site_info->base_uri->port($port));

my $posts = $dbh->resultset('Post');

my @posts = $posts->all;

foreach my $post (@posts) {
    my @wms = $webmention_mgr->get_webmentions_from_post($post);
    my $res = $webmention_mgr->send_webmentions(@wms);

    ok($$res{attempts} == 0, "No webmention attempts if no link is detected in the post body");

}

my $post_with_webmentions = shift(@posts);
my $webmention_target_uri = Mojo::URL->new($posts[0]->uri)->base($t->app->site_info->base_uri->port($port))->to_abs;
my $body = $post_with_webmentions->body();

$body .= sprintf "\n<p>Check <a href='%s'>this</a> out!!</p>", $webmention_target_uri;

$post_with_webmentions->body($body);

$post_with_webmentions->update();
$t->get_ok('/');

my @webmentions = $webmention_mgr->get_webmentions_from_post($post_with_webmentions);

ok(@webmentions == 1, 'Correct amount of one (1) webmention created');

my @webmentions_to_save;
my $payload;
foreach my $webmention (@webmentions) {
    isa_ok($webmention, 'Web::Mention', 'output from Model::Webmentions');
    isa_ok($webmention, 'Web::Mention::Mojo', 'output from Model::Webmention');

    $webmention->ua($t->ua);
    $payload = $webmention->TO_JSON();

    cmp_ok($webmention->source, 'eq',
        Mojo::URL->new($t->app->site_info->base_uri)->port($port)->path($post_with_webmentions->path),
        'Webmention source is OK');
    cmp_ok($webmention->target, 'eq', $webmention_target_uri, "Webmention target is OK");

    ok($webmention->verify, 'Webmention is verified OK');

    push(@webmentions_to_save, $webmention);

    cmp_ok($webmention->author->name, 'eq', $post_with_webmentions->author_name(), 'Webmention author is OK');

    cmp_ok($webmention->endpoint, 'eq', $webmention_uri->to_abs, "Webmention endpoint is OK");

    ok($webmention->send, 'Webmention delivered and accepted OK');

}

my $wms = $dbh->resultset('Webmention');

foreach my $verified_webmention (@webmentions_to_save) {

    ok(my $webmention_db = $wms->from_webmention($verified_webmention),
        'Create webmention DB model from Web::Mention object');
    ok(defined($webmention_db), 'Successful creation of Webmention DB object.');

    cmp_ok($webmention_db->in_storage, '==', 0);

    ok($webmention_db->insert, "New webmention saved in DB");

    cmp_ok($webmention_db->in_storage, '==', 1);

    TODO: {
        local $TODO = "Sending the same webmention again after it's been saved should return the one in storage";
        ok(my $webmention_db_again = $wms->from_webmention($verified_webmention));
        cmp_ok($webmention_db->in_storage, '==', 0);
    }



}

done_testing();

