package Tuvix::Watcher;
use strict;
use warnings FATAL => 'all';

use Tuvix::ExtendedPlerd;

use Tuvix::PlerdHelper;
use File::ChangeNotify;
use Try::Tiny;

use FindBin;

use Mojo::Log;
use Mojo::Unicode::UTF8;
use Mojo::Util qw(slugify);

use Moose;
use Fcntl qw( :flock );

has 'log' => (
    'is' => 'ro',
    isa  => 'Mojo::Log',
    default => sub { Mojo::Log->new() }
);

has 'config' => (
    isa => 'HashRef',
    is => 'ro',
    required => 1
);

has watcher_pidfile => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1
);

sub _build_watcher_pidfile {
    return shift->{config}->{watcher_pidfile} ||
        "$FindBin::Bin/../watcher.pid"
}


sub _watch_directory {
    my ($self, $ppid) = @_;

    my $watcher;
    my $plerd;
    my $plerd_helper;
    my $log = $self->log;
    my $config = $self->config;

    try {
        my $filter;
        $plerd = Tuvix::ExtendedPlerd->new($config);
        $plerd_helper = Tuvix::PlerdHelper->new(
            db      => \@{$$config{'db'}},
            db_opts => $$config{'db_opts'},
            plerd   => $plerd,
            log     => $log);

        my $trigger = sprintf '\.(%s)$', join('|', keys %{$plerd->post_triggers});

        $log->info("Fucking shit filter $trigger ");
        $filter = qr/$trigger/;

        $watcher = File::ChangeNotify->instantiate_watcher(
            directories => [ $plerd->source_directory . '' ],
            filter      => $filter
        );
    }
    catch {
        $log->error("Watcher couldn't start Tuvix::ExtendedPlerd and/or PlerdHelper: $_");
    };

    my $triggers = $plerd->post_triggers;
    $log->info("Started watching " . $plerd->source_directory);
    while( -e "/proc/${ppid}" ) {
        if (my @events = $watcher->new_events) {
            my $event;
            try {
                foreach (@events) {
                    $event = $_;
                    $log->info(sprintf "Processing %s %s", $event->type, $event->path);

                    # The type of event. This must be one of "create", "modify", "delete", or "unknown".
                    # https://metacpan.org/pod/File::ChangeNotify::Event
                    if ($event->type eq 'create' or $event->type eq 'modify') {
                        my $file = Path::Class::File->new($event->path);
                        my $post;

                        foreach my $trigger (keys %{$triggers}) {

                            $log->info("testing if file: $file matched /\.$trigger\$/");
                            if ($file =~ m/\.$trigger$/i) {
                                $log->info("file: $file matched /\.$trigger\$/");
                                $post = $$triggers{$trigger}->new(plerd => $plerd, source_file => $file);
                                last;
                            }
                        }
                        if ($post) {
                            $plerd_helper->create_or_update_post($post);
                            if ($$config{send_webmentions}){
                                my $report = $post->send_webmentions;

                                $log->info(sprintf "Webmentions attempts:%s delivered:%s sent:%s ",
                                    $$report{attempts} // -1, $$report{delivered} // -1, $$report{sent} // -1);
                            }
                        }
                        else {
                            $log->error(
                                sprintf "Could not make Plerd::Post of any type from  %s", $event->path);
                        }
                    }
                    elsif ($event->type eq 'delete') {
                        $plerd_helper->delete_post_from_filename(Path::Class::File
                            ->new($event->path)
                            ->basename);
                    }
                }
            }
            catch {
                my $reason = shift || "Unknown reason";
                $log->error(defined $event
                    ? sprintf "Unable to %s %s: %s", $event->type, $event->path, $reason
                    : "Unexpected error encountered: $reason");
            }
        }
        sleep 1;
    };
    $log->info("Stopped watching " . $plerd->source_directory . ". parent dead: $ppid");
}

sub start {
    my $self = shift;
    my $pid = $$;

    open(my $fh, '+>', $self->watcher_pidfile) or die
        sprintf "Unable to open watcher pidfile: %s: %s", $self->watcher_pidfile, $!;

    unless (flock($fh, LOCK_EX|LOCK_NB)) {
        $self->log->error(
            sprintf ("Not starting the directory watcher: Unable to acquire pid file: %s lock:%s",
                $self->watcher_pidfile, $!));
    } else {
        my $child_pid = fork();
        if ($child_pid){
            return $child_pid;
        } else {
            truncate $fh, 0;
            print $fh $$;
            $self->log->info("Starting directory watcher with pid $$ .");
            $self->_watch_directory($pid);
            close($fh);
        }
    }
    return 0;
}


1;

