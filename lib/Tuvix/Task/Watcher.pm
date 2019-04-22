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
    my $log = Mojo::Log->new;
    
    $app->minion->add_task(watch_directory => sub {
        my $job = shift;
        my $watcher;
        my $plerd;
        my $plerd_helper;

        return $job->finish('Previous job is still active') unless
            my $guard = $app->minion->guard('watch_dir_lock', 7200);

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
            $log->error("Watcher couldn't start Plerd and/or PlerdHelper: $_");
            $job->fail("Watcher couldn't start Plerd and/or PlerdHelper: $_");
        };

        my $triggers = $plerd->post_triggers;
        $job->app->log->info("Started watching " . $plerd->source_directory);
        while (my @events = $watcher->wait_for_events) {
            if (@events) {
                my $event;
                try {
                    foreach (@events) {
                        $event = $_;
                        $job->app->log->info(sprintf "Processing %s %s", $event->type, $event->path);
                        # The type of event. This must be one of "create", "modify", "delete", or "unknown".
                        # https://metacpan.org/pod/File::ChangeNotify::Event
                        if ($event->type eq 'create' or $event->type eq 'modify') {
                            my $file = Path::Class::File->new($event->path);
                            my $post;

                            foreach my $trigger (keys %{$triggers}) {

                                $job->app->log->info("testing if file: $file matched /\.$trigger\$/");
                                if ($file =~ m/\.$trigger$/i) {
                                    $job->app->log->info("file: $file matched /\.$trigger\$/");
                                    $post = $$triggers{$trigger}->new(plerd => $plerd, source_file => $file);
                                    last;
                                }
                            }
                            if ($post) {
                                $plerd_helper->create_or_update_post($post);
                                $post->send_webmentions if $job->app->site_info->send_webmentions;
                            }
                            else {
                                $job->app->log->error(
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
                    $job->app->log->error(defined $event
                        ? sprintf "Unable to %s %s: %s", $event->type, $event->path, $reason
                        : "Unexpected error encountered: $reason");
                }
            };
        };
        # Should not exit event loop.. better retry
        #return $job->retry({ delay => 30 });
    });
}

1;