#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}


plan tests => 155;

use_ok('Tuvix::Model::Webmentions');

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

$t->app->helper(base_url => sub {
    Mojo::URL
        ->new()
        ->base($t->app->site_info->base_uri->port($port));
});

my $posts = $dbh->resultset('Post');
my @posts = $posts->all;

# Now proceed with some tests

$t->get_ok('/posts')
    ->header_is(Link => sprintf '<%s>; rel="webmention"', $webmention_uri->to_abs);

$t->post_ok('/webmention')
    ->status_is(400)
    ->content_like(qr/Malformed webmention:/);

$t->post_ok('/webmention' => form => {
    source => 'http://localhost/foo_source',
    target => 'http://localhost/foo_target_som_inte_finns' })
    ->status_is(404)
    ->content_like(qr/Target not found/);

$t->post_ok('/webmention' => form => {
    source => 'http://localhost/foo_source',
    target =>  Mojo::URL->new($posts[-1]->uri)->base($t->app->site_info->base_uri->port($port))->to_abs })
    ->status_is(202)
    ->content_like(qr/The webmention has arrived and will be delt with in due time/);

$t->get_ok(Mojo::URL->new($posts[-1]->uri)->base($t->app->site_info->base_uri->port($port))->to_abs )
    ->header_is(Link => sprintf '<%s>; rel="webmention"', $webmention_uri->to_abs);


# TODO: Deprecate
my $webmention_mgr = Tuvix::Model::Webmentions->new(base_uri => $t->app->site_info->base_uri->port($port));



foreach my $post (@posts) {
    my @wms = $webmention_mgr->get_webmentions_from_post($post);
    my $res = $webmention_mgr->send_webmentions(@wms);

    ok($$res{attempts} == 0, "No webmention attempts if no link is detected in the post body");

}

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

$many_webmentions =~ s<http://example.com/[a-z]+-target><$webmention_target_uri>g;

my $body = $post_with_webmentions->body();
$body .= $many_webmentions;

$post_with_webmentions->body($body);

$post_with_webmentions->update();
$t->get_ok('/');

my @webmentions = $webmention_mgr->get_webmentions_from_post($post_with_webmentions);

cmp_ok(@webmentions, '==', 6);

# Set the UA so that it can be tested w the $t: Mojo::Test
$_->ua($t->ua) for @webmentions;
my @types = map {$_->type} @webmentions;

my @webmentions_to_save;
my $payload;
foreach my $webmention (@webmentions) {
    isa_ok($webmention, 'Web::Mention', 'output from Model::Webmentions');
    isa_ok($webmention, 'Web::Mention::Mojo', 'output from Model::Webmention');

    #$webmention->ua($t->ua);
    $payload = $webmention->TO_JSON();

    cmp_ok($webmention->source, 'eq',
        Mojo::URL->new($t->app->site_info->base_uri)->port($port)->path($post_with_webmentions->path),
        'Webmention source is OK');
    cmp_ok($webmention->target, 'eq', $webmention_target_uri, "Webmention target is OK");

    ok($webmention->verify, 'Webmention is verified OK');

    ok(defined $webmention->$_->base, "webmention [" .
        $webmention->$_->to_string . "] has base for $_ url") for qw/original_source source target/;

    push(@webmentions_to_save, $webmention);

    cmp_ok($webmention->author->name, 'eq', $post_with_webmentions->author_name(), 'Webmention author is OK');

    cmp_ok($webmention->endpoint, 'eq', $webmention_uri->to_abs, "Webmention endpoint is OK");

    ok($webmention->send, 'Webmention delivered and accepted OK');

}

cmp_ok(@webmentions_to_save, '==', @webmentions);

foreach my $verified_webmention (@webmentions_to_save) {

    ok(my $webmention_db = $dbh->resultset('Webmention')->from_webmention($verified_webmention),
        'Create webmention DB model from Web::Mention object');
    ok(defined($webmention_db), 'Successful creation of Webmention DB object.');

    TODO: {
        local $TODO = "A page may have multiple webmentions in it from same source to same target."
            . "Figure out what is the proper way to handle such a situation.";
        cmp_ok($webmention_db->in_storage, '==', 0);
    }


    ok($webmention_db->insert_or_update, sprintf "New webmention (type %s) saved in DB", $webmention_db->type);

    cmp_ok($webmention_db->in_storage, '==', 1);

    ok(my $webmention_db_again = $dbh->resultset('Webmention')->from_webmention($verified_webmention));
    cmp_ok($webmention_db_again->in_storage, '==', 1);
    ok(!$webmention_db_again->is_changed(), 'Webmention should be just gotten 2nd time')

}

my $wms = $dbh->resultset('Webmention');

TODO: {
    local $TODO = "Read how the spec says about same webmention source -> target but the kind is different!";
    cmp_ok($wms->count, '==', @webmentions_to_save);
}
cmp_ok($wms->count, '>', 0);

while (my $wm = $wms->next) {
    my $post = $wm->get_post;
    cmp_ok($post->path, 'eq', $wm->path);
    isa_ok($post, 'Tuvix::Schema::Result::Post', '$wm->get_post returns its associated post and nothing else');
    cmp_ok($post->get_webmentions->search({ 'path' => $wm->path })->next->path, 'eq', $wm->path,
        'The Post associated with the Webmention is associated back to the same webmention');

    $t->get_ok($wm->path)
        ->status_is(200)
        ->content_like(qr\alt="Foobar avatar" \i);

}

done_testing();

