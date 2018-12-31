use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestData qw\create_testdb\;

use Mojolicious::Commands;

plugin 'Config' => { file => 'assets/tuvix.conf' };

chdir "$FindBin::Bin";

my $dbh = create_testdb;

my $t = Test::Mojo->new('Tuvix', app->config);

$t->app->helper(posts => sub {
    Tuvix::Model::Posts->new(schema => $dbh)
});

$t->get_ok('/')->status_is(302);

$t->get_ok('/posts')->status_is(200)->content_like(qr/Unit Test Blog Title/i);

$t->get_ok('/posts/2018-10-28-another-day-in-paradise')
    ->status_is(200)
    ->content_like(qr/Phil Collins/i);

$t->get_ok('/posts?feed=rss')
    ->status_is(200)
    ->content_like(qr/rss version="2.0"/);

done_testing();
