use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Unicode::UTF8;
use Tuvix::ExtendedPlerd;
use Tuvix::PlerdHelper;

use FindBin;
BEGIN {unshift @INC, "$FindBin::Bin/../lib"}
use Mojolicious::Commands;

our @ISA = qw(Exporter);
our @EXPORT = qw(create_testdb);

sub create_testdb {

    plugin 'Config' => { file => 'assets/tuvix.conf' };

    chdir "$FindBin::Bin";
    plugin 'DefaultHelpers';

    my $config_ref = app->config();

    my $plerd = Tuvix::ExtendedPlerd->new($config_ref);
    my $ph = Tuvix::PlerdHelper->new(
        db      => \@{app->config('db')},
        db_opts => app->config('db_opts'),
        plerd   => $plerd
    );

    $ph->deploy_schema(1);
    $ph->publish_all;

    return $ph->schema()->clone();
}

1;