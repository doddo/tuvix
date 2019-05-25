use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use TestApp qw\create_testapp\;

sub post_in_dom {
    my $t = shift;
    my $title = shift;

    return grep {$_->at("a")->text eq $title}
        @{$t->tx->res->dom->find("h1.post-title")}
}

my $t = create_testapp;

$t->get_ok('/posts', form => { tag => "coffee" })
    ->status_is(200);

$t->tx->res->dom->find("h1.post-title");


ok(post_in_dom($t, 'New coffee machine'), "New coffee machine post found through coffee tag");
ok(!post_in_dom($t, 'Another day in paradise'), "Another day in paradise post not found through coffee tag");

$t->get_ok('/posts', form => { tag => "hardships" })
    ->status_is(200);

ok(post_in_dom($t, 'Life is tough'), "Life is tough post found through hardships tag");
ok(!post_in_dom($t, 'New coffee machine'), "New coffee machine post not found through hardships tag");

$t->tx->res->dom->find("h1.post-title");

$t->get_ok('/posts', form => { tag => "🐖🐖🐖🐖🐖TAG WHICH DOES NOT EXIST" })
    ->status_is(404);

# TODO add some more tests here. Maybe some emoji tests.

done_testing();