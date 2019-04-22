#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}


plan tests => 31;

use TestData qw\create_testdb\;

my $dbh = create_testdb;

my $posts = $dbh->resultset('Post');

my $found = 0;

while (my $post = $posts->next) {
    ok(defined $post->title);

    if ($post->title eq 'About this blog') {
        cmp_ok($post->type, 'eq', 'page');
        $found = 1;
    }
    else {
        cmp_ok($post->type, 'eq', 'post');
    }

    isa_ok $post, 'Tuvix::Schema::Result::Post';
}

cmp_ok($found, '==', 1, "The page post was found");

done_testing()