use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw\create_testapp\;

my $t = create_testapp;

$t->get_ok('/posts/2019-04-29-markdown-table')
    ->status_is(200)
    ->content_like(qr{<td>Pizza</td>});


done_testing();