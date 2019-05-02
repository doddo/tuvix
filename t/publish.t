#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}


plan tests => 27;

use TestData qw\create_testdb\;

my $dbh = create_testdb;

my $posts = $dbh->resultset('Post');
my $tags = $dbh->resultset('Tags');

my $guid_for_post_with_tags = '9B332458-062D-11E9-A44F-FFEE3F391ACD';
my @expected_tags = ('coffee', 'coffee machine');

my $post_with_tags;

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

    if ($post->guid eq '9B332458-062D-11E9-A44F-FFEE3F391ACD') {
        $post_with_tags = $post;
    }
    elsif ($post->guid eq '9B3386F0-062D-11E9-A44F-FFEE3F391ACD') {
        cmp_ok($post->get_tags()->next->tag, 'eq', 'hardships',
            'post can get tag with get_tags')
    }

    isa_ok $post, 'Tuvix::Schema::Result::Post';
}

ok($post_with_tags, 'found post with tags');

ok(my $tags_from_post_with_tags = $dbh->resultset('Tags')->search({ guid => $guid_for_post_with_tags }));

cmp_ok($tags_from_post_with_tags->count, '==', 2, "Tags from post contains excactly two tags");

my @found_tags = sort {$a cmp $b} map {$_->tag} $tags_from_post_with_tags->all;

is_deeply(\@found_tags, \@expected_tags, "the right tags are in there");

cmp_ok($found, '==', 1, "The page post was found");

done_testing()