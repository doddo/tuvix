#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use App::Daemon qw(daemonize);
use File::ChangeNotify;

use Mojo::Log;
use Mojo::Unicode::UTF8;
use Mojo::Util qw(slugify);
use Mojolicious::Lite;

use Path::Class::File;

use Plerd;
use Plerd::Util;

use Try::Tiny;

use Tuvix;
use Tuvix::PlerdHelper;

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

my $watcher;
my $help = 0;
my $send_webmentions = 0;
my $config_file = "$FindBin::Bin/../tuvix.conf";

GetOptions("help"      => \$help,
    "send-webmentions" => \$send_webmentions,
    "config-file=s"    => \$config_file)
    or pod2usage(-exitval => 2, -verbose => 1);

pod2usage(-exitval => 0, -verbose => 1) if $help;

die(sprintf "Unable to locate config file '%s'", $config_file)
    unless (-e $config_file);

plugin 'Config' => { file => $config_file };
plugin 'DefaultHelpers';

my $log = Mojo::Log->new;

my $config_ref = app->config('plerd');
my $plerd = Plerd->new($config_ref);

my $ph = Tuvix::PlerdHelper->new(
    db      => \@{app->config('db')},
    db_opts => app->config('db_opts'),
    plerd   => $plerd,
    log     => $log
);

try {
    my $filter;

    my $trigger = defined(keys %{$plerd->post_triggers})
        ? sprintf '\.(md|markdown|%s)$', join('|', keys %{$plerd->post_triggers})
        : '\.(md|markdown)$';

    $filter = qr/$trigger/;

    $watcher = File::ChangeNotify->instantiate_watcher(
        directories => [ $plerd->source_directory . '' ],
        filter      => $filter,
    );
    $log->info("Started watching " . $plerd->source_directory);
}
catch {
    $log->error("Couldn't start Plerd: $_");
};

while (my @events = $watcher->wait_for_events) {
    if (@events) {
        my $event;
        my $triggers = $plerd->post_triggers;
        try {
            for $event (@events) {
                $log->debug(sprintf "Processing %s %s", $event->type, $event->path);
                # The type of event. This must be one of "create", "modify", "delete", or "unknown".
                # https://metacpan.org/pod/File::ChangeNotify::Event
                if ($event->type eq 'create' or $event->type eq 'modify') {
                    my $file = Path::Class::File->new($event->path);
                    my $post;

                    foreach my $trigger (keys %{$triggers}) {
                        if ($file =~ m/\.$trigger$/i) {
                            $post = $$triggers{$trigger}->new(plerd => $plerd, source_file => $file);
                            last;
                        }
                    }
                    if ($post){
                        $ph->create_or_update_post($post);
                        $post->send_webmentions if $send_webmentions;
                    }
                    else {
                        $log->error(sprintf "Could not make Plerd::Post of any type from  %s", $event->path);
                    }
                }
                elsif ($event->type eq 'delete') {
                    $ph->delete_post_from_filename(Path::Class::File
                        ->new($event->path)
                        ->basename);
                }
            }
        }
        catch {
            if ($event) {
                $log->error(sprintf "Unable to %s %s: %s", $event->type, $event->path, $_ || "Unknown reason");
            }
            else {
                $log->error("Unexpected error encountered: $_");
            }
        };
    }
}

sub handle_term_signal {
    exit;
}


# TODO:


1;

__END__
=encoding utf-8

=head1 NAME

plerdwatcher_db.pl - Watch plerd source directory for changes and act upon them

=head1 SYNOPSIS

plerdall_db.pl  [option ...]

 Options:
   --config-file       Path to the tuvix.conf file
   --send-webmentions  Send webmentions from new or updated posts if applicable
   --help              brief help message

=head1 OPTIONS

=over 4

=item B<--help>

Print a brief help message and exits.

=item B<--config-file>

Path to the tuvix.conf config file.

=item B<--send-webmentions>

If a published post contains webmentions, this param specifies whether plerd should attempt to send them out or not

=back

=cut
