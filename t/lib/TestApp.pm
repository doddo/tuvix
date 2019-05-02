package TestApp;
use strict;
use warnings FATAL => 'all';

use Mojo::Base -strict;

use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use FindBin;

our @ISA = qw(Exporter);
our @EXPORT = qw(create_testapp $DBH);


BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use TestData qw\create_testdb\;


sub create_testapp {

    plugin 'Config' => { file => $FindBin::Bin . '/assets/tuvix.conf' };

    my $dbh = create_testdb;

    my $t = Test::Mojo->new('Tuvix', app->config);

    $t->app->helper(posts => sub {
        Tuvix::Model::Posts->new(schema => $dbh)
    });

    # To get the webmention to say the full correct address
    my $port = $t->get_ok('/')->tx->remote_port;

    $t->app->helper(webmention_url => sub {
        Mojo::URL
            ->new('/webmention')
            ->base(Mojo::URL->new($t->app->site_info->base_uri->port($port)));
    });

    $t->app->helper(base_url => sub {
        Mojo::URL
            ->new()
            ->base($t->app->site_info->base_uri->port($port));
    });

    $t->app->helper(schema => sub {
        return $dbh;
    });

    $t->app->helper(ua => sub {$t->ua});

    $t->ua->connect_timeout(1);
    $t->ua->request_timeout(1);

    return $t;
}

1;