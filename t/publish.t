#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}


plan tests => 30;


use TestData qw\create_testdb\;

my $dbh = create_testdb;

my $posts = $dbh->resultset('Post');

while (my $post = $posts->next) {
    ok(defined $post->title);

    if ($post->title eq 'About this blog'){
        TODO: {
            local $TODO = "Classify posts based on the 'type' tag found (optionally) in it.";
            cmp_ok($post->type, 'eq', 'page');
        }
    } else {
        cmp_ok($post->type, 'eq', 'post');
    }

    isa_ok $post, 'Tuvix::Schema::Result::Post';
}

done_testing()