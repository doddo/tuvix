package Tuvix::Command::deploy_files;
use strict;
use warnings FATAL => 'all';

use FindBin;
BEGIN {unshift @INC, "$FindBin::Bin/../.."}

use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';
use Tuvix::Util qw/cp_r mkdir_p/;

use File::Spec::Functions 'catdir';
use Cwd 'abs_path';
use Carp qw'croak';

has 'description' => 'Deploy or update Tuvix files.';
has 'usage' => <<"USAGE";
$0 deploy [files|db] [OPTIONS]
OPTIONS:
  -v , --verbose    Verbose output
  -n , --noop       Don't do nothing but print what it whould've done
  -o , --overwrite  Overwrite target files if present
  -b , --basedir    select root directory to deploy files to.

USAGE


sub run {
    my ($self, @args) = @_;

    getopt(
        \@args,
        'o|overwrite' => \my $version,
        'v|verbose'   => \my $verbose || 0,
        'n|noop'      => \my $noop,
        'b|basedir=s' => \my $basedir,
    );

    my $app = $self->app;
    my $log = Mojo::Log->new(level => $verbose ? 'debug': 'warn');

    my $_get_path = sub {
        my $dir = shift;

        if ($basedir) {
            return catdir($basedir, 'templates') if $dir eq 'template_path';
            return catdir($basedir, 'pub') if $dir eq 'publication_path';
            return catdir($basedir, $dir =~ s/_path//r);
        }
        elsif ($app->conf($dir)) {
            $app->conf($dir)
        }
        elsif ($self->app->conf('path')) {
            return catdir($app->conf('path'), $dir =~ s/_path//r)
        }
        else {
            croak "no suitable path found for $dir. " .
                "- specify it im the config file, or a base path with --basedir flag."
        }
    };

    $log->info("Creating directories...");

    foreach my $dir (qw/source_path publication_path/) {
        # source_path
        my $target = $_get_path->($dir);

        $log->info("creating $target.");
        mkdir_p(
            target  => $target,
            verbose => $verbose,
            noop    => $noop,
            log     => $log,
        )
    }

    $log->info("Deploying templates...");
    cp_r(
        source  => abs_path($app->home->child('templates')),
        target  => abs_path($_get_path->('template_path')),
        verbose => $verbose,
        noop    => $noop,
        log     => $log,

    );
}


1;
