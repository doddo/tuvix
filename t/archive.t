use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw\create_testapp\;

my $t = create_testapp;

$t->get_ok('/')->status_is(302);
$t->get_ok('/posts')->status_is(200);
$t->get_ok('/posts/archive')
    ->status_is(200);
$t->get_ok('/posts/archive'
    => form => {y => '2019', m => '01'})
    ->content_like(qr{<a href="/posts/archive\?month=\d+&year=2018">Older posts...</a>}i)
    ->content_unlike(qr/newer post/i);

done_testing()