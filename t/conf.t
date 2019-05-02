use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

plan tests => 12;


plugin 'Config' => { file => $FindBin::Bin . '/assets/tuvix.conf' };
my %reference_settings = (
    base_uri         => 'http://localhost',
    title            => 'Unit Test Blog Title',
    author_name      => 'Foobar',
    author_email     => 'foo@bar.re',
    author_photo     => '/assets/generic_face.png',
    author_bio       => 'I love life every day.',
);


ok (my $t = Test::Mojo->new('Tuvix', app->config), 'can load test config');

cmp_ok($t->app->websocket_url->scheme, 'eq', 'ws', 'websocket url scheme is ws when url is http');
cmp_ok($t->app->site_info->base_uri->scheme, 'eq', 'http', 'conf url is http');

foreach my $key (keys %reference_settings){
    if ($key eq 'author_photo'){
        my $abs_url = Mojo::URL->new(
            $t->app->site_info->base_uri->path($reference_settings{$key}));
        is($abs_url, 'http://localhost/assets/generic_face.png', 'absolute URL for author_photo created from path');
    } else {
        is($t->app->site_info->$key, $reference_settings{$key}, $key . ' matches' )
    }
}


${app->config}{'base_uri'} = 'https://localhost';

ok (my $t2 = Test::Mojo->new('Tuvix', app->config), 'can load test config2');

cmp_ok($t2->app->websocket_url->scheme, 'eq', 'wss', 'websocket url scheme is ws when url is https');
cmp_ok($t2->app->site_info->base_uri->scheme, 'eq', 'https', 'conf url is https');


done_testing()