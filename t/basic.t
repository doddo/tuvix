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

$t->get_ok('/posts')
    ->status_is(200)
    ->content_like(qr/Unit Test Blog Title/i)
    ->content_like(qr{This is a blog by <a href="mailto:foo\@bar.re">Foobar</a>})
    ->content_like(qr{<p>Powered by <a href="https://github.com/doddo/tuvix">Tuvix</a> \(powered by <a href="http://jmac.org/plerd">Plerd</a>\).</p>});

$t->get_ok('/posts/2018-10-28-another-day-in-paradise')
    ->status_is(200)
    ->content_like(qr/Phil Collins/i);

$t->get_ok('/posts?feed=rss')
    ->status_is(200)
    ->content_like(qr/rss version="2.0"/);


done_testing();
