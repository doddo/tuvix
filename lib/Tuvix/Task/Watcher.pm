package Tuvix::Task::Watcher;

use Tuvix::ExtendedPlerd;

use Tuvix::PlerdHelper;
use File::ChangeNotify;
use Try::Tiny;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Log;
use Mojo::Unicode::UTF8;
use Mojo::Util qw(slugify);


sub register {
    my ($self, $app) = @_;
    
    $app->minion->add_task(watch_directory => sub {
        my $job = shift;
        my $watcher;
        my $plerd;
        my $plerd_helper;
        my $log = $job->app->log;

        try {

            my $filter;
            $plerd = Tuvix::ExtendedPlerd->new($app->config());
            $plerd_helper = Tuvix::PlerdHelper->new(
                db      => \@{$app->config('db')},
                db_opts => $app->config('db_opts'),
                plerd   => $plerd,
                log     => $job->app->log);

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
            $job->fail("Watcher couldn't start Tuvix::ExtendedPlerd and/or PlerdHelper: $_");
        };

        my $triggers = $plerd->post_triggers;
        $log->info("Started watching " . $plerd->source_directory);
        while(sleep 1) {
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
                                if ($job->app->site_info->send_webmentions){
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
        };

        $log->info("Stopped watching " . $plerd->source_directory);

        return $job->retry({ delay => 2 });
    });
}

1;