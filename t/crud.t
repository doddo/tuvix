#!/usr/bin/perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}


my $post;

plan tests => 9;

use TestData qw\create_testdb\;

my $dbh = create_testdb;
my $posts = $dbh->resultset('Post');

ok ($post = $posts->find({title => 'Life is tough'}), "Post found");

$post->title("Life is awful");

ok ($post->insert_or_update(), 'Post title can be renamed');

ok (! $posts->find({title => 'Life is tough'}), "Post no longer found");

ok ($post = $posts->find({title => 'Life is awful'}), "Post with new title found");

ok ($post->delete, "Post deleted (with Tags)");

ok (my $post_by_guid = $posts->find_or_new({ guid => '9B329286-062D-11E9-A44F-FFEE3F391ACD'}), "Post found by guid");

$post_by_guid->path('new-path');

ok ($post_by_guid->insert_or_update(), "Post can change path");

$post_by_guid->source_file('/new/source/file');

ok ($post_by_guid->insert_or_update(), "Post can change source_file");

$post_by_guid->guid("abba");

ok ($post_by_guid->insert_or_update(), "Post cat change guid");

done_testing();
