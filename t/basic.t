use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use Mojolicious::Commands;

my $t = Test::Mojo->new('Tuvix');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();
