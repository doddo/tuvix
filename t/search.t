use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw\create_testapp\;

my $t = create_testapp;

$t->post_ok('/posts/search')
    ->status_is(400)
    ->content_like(qr{Please input a query in the search box\.});

$t->post_ok('/posts/search', form => {  q => "🐖🐖🐖🐖🐖PAGE WHICH DOES NOT EXIST"})
    ->status_is(404)
    ->content_like(qr{Found 0 posts});

$t->post_ok('/posts/search', form => { q => "About"})
    ->status_is(200)
    ->content_like(qr{Found 2 posts})
    ->content_like(qr{About this blog})
    ->content_like(qr{New coffee machine});

$t->post_ok('/posts/search', form => {  q => "yer"})
    ->status_is(200)
    ->content_like(qr{Found 1 posts})
    ->content_like(qr{new year 2019});


$t->post_ok('/posts/search', form => {  q => "💩"})
    ->status_is(200)
    ->content_like(qr{Found 1 posts})
    ->content_like(qr{Food for thought.});


done_testing();
