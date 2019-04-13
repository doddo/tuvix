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
$t->get_ok('/posts')->status_is(200);
$t->get_ok('/posts/archive')
    ->status_is(200);
$t->get_ok('/posts/archive'
    => form => {y => '2019', m => '01'})
    ->content_like(qr{<a href="/posts/archive\?month=\d+&year=2018">Older posts...</a>}i)
    ->content_unlike(qr/newer post/i);
done_testing()