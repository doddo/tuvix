use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw\create_testapp\;

my $t = create_testapp;

$t->get_ok('/posts', form => { tag => "coffee" })
    ->content_like(qr{<span class="p-name">New coffee machine</span>})
    ->content_unlike(qr{<span class="p-name">Another day in paradise</span>});

$t->get_ok('/posts', form => { tag => "hardships" })
    ->content_like(qr{<span class="p-name">Life is tough</span>})
    ->content_unlike(qr{<span class="p-name">New coffee machine</span>});

$t->get_ok('/posts', form => { tag => "🐖🐖🐖🐖🐖TAG WHICH DOES NOT EXIST" })
    ->status_is(404);

# TODO add some more tests here.

done_testing();