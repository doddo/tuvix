#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

#plan tests => 10;

use_ok('Tuvix::Model::Webmentions');

use TestData qw\create_testdb\;

my $dbh = create_testdb;

my $config = app->config;

my $t = Test::Mojo->new('Tuvix', $config);

$t->app->helper(posts => sub {
    Tuvix::Model::Posts->new(schema => $dbh)
});

$t->app->helper(schema => sub {
    $dbh;
});


# To get the webmention to say the full correct address
my $port = $t->get_ok('/')->tx->remote_port;

$t->app->helper(webmention_url => sub {
    Mojo::URL
        ->new('/webmention')
        ->base(Mojo::URL->new($t->app->site_info->base_uri->port($port)));
});

$t->app->helper(base_url => sub {
    Mojo::URL
        ->new()
        ->base($t->app->site_info->base_uri->port($port));
});

my $webmention_mgr = Tuvix::Model::Webmentions->new(base_uri => $t->app->site_info->base_uri->port($port));

my $posts = $dbh->resultset('Post');

my @posts = $posts->all;
my $post_with_webmentions = shift(@posts);
my $webmention_target_uri = Mojo::URL->new($posts[0]->uri)->base($t->app->site_info->base_uri->port($port))->to_abs;
my $many_webmentions = <<'END_BODY';
       <!-- a Webmention from a source can have ony one type per target -->
       <a href="http://example.com/reply-target" class="u-in-reply-to">A reply.</a>
       <a href="http://example.com/mention-target">A generic mention.</a></p>
       <a href="http://example.com/mention-target">Check this out.</a></p>
       <a href="http://example.com/quotation-target" class="u-quotation-of">A quotation.</a></p>
       <a href="http://example.com/like-target" class="u-like-of">A like.</a></p>
       <a href="http://example.com/repost-target" class="u-repost-of">A repost.</a></p>

END_BODY
$many_webmentions =~ s<http://example.com/[a-z]+-target><$webmention_target_uri>g;;

my $body = $post_with_webmentions->body();
$body .= $many_webmentions;
$post_with_webmentions->body($body);
$post_with_webmentions->update();

my @webmentions = $webmention_mgr->get_webmentions_from_post($post_with_webmentions);

foreach my $webmention (@webmentions) {
    $webmention->ua($t->ua);
    isa_ok($webmention, 'Web::Mention');
    ok($webmention->verify, 'Webmention is verified OK');
    ok($webmention->is_tested, 'Webmention is tested');
    like($webmention->target, qr{http://localhost}, 'webmention must have a (local) target ');
    like($webmention->endpoint, qr{http://localhost}, 'webmention must have a (local) endpoint');
    ok($webmention->send, 'webmention can be sent OK');

    ok(!$webmention->error, "no errros");
}

my $worker = $t->app->minion->worker;

while (my $job = $worker->register->dequeue(0)) {

    ok($job->perform, 'job can preform OK.');
        cmp_ok($job->info->{result}, 'eq', 'successful');
}

done_testing();

