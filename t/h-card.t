#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw/create_testapp/;

my $t = create_testapp;

$t->get_ok('/posts')
    ->status_is(200);

ok (my $hcards = $t->tx->res->dom->at('data.p-author.h-card'),
    'h-cards located in dom');

cmp_ok $hcards->find("data.p-name")->first->val,
    'eq', $t->app->site_info->author_name, "p-name name in there looks OK";

ok (my $url_dom = $hcards->find("data.u-url,u-uid")->first, "u-url in there");

cmp_ok $url_dom->val,
    'eq', $t->app->base_url->to_abs, "u-url in there looks OK";

cmp_ok $url_dom->attr('rel'),
    'eq', 'me', "u-url rel in there is me";

ok (my $email_dom = $hcards->find("a.u-email")->first, "e-mail in there");

cmp_ok $email_dom->attr('href'),
    'eq', $t->app->site_info->author_email, "u-email in there looks OK";

cmp_ok $email_dom->attr('rel'),
    'eq', 'me', "u-email rel in there is me";

cmp_ok my $author_photo = $hcards->find("data.u-photo")->first->val,
    'eq', $t->app->site_info->author_photo->to_abs, "u-photo in there and looks OK";


ok( Mojo::URL->new($author_photo)->is_abs , "Author photo should be absolute");

cmp_ok $hcards->find("p.p-note")->first->text,
    'eq', $t->app->site_info->author_bio, "p-note in there and looks OK";

done_testing();

