package Tuvix::Task::ProcessWebmention;
use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(recieve_webmention => sub {
        my $job = shift;
        while (my $webmention = shift) {
            $job->app->log->info('Processing incoming webmention from: ' . $webmention->source);
            try {
                $webmention->verify()
            }
            catch {
                my $err = shift || 'unknown error';
                $job->fail('Invalid webmention from: %s to %s: %s ',
                    $webmention->source, $webmention->target, $err);
            };

            if ($webmention->is_verified) {
                $job->app->log->info('Webmention of type "%s" from %s to %s is verifed.',
                    $webmention->source, $webmention->target);
                # SOMETHING->ADD_WEBMENTION
            }
            else {
                $job->app->log->info('Not able to verify webmention from, maybe a delete: %s to %s.',
                    $webmention->source, $webmention->target);
                # SOMETHING->POSSIBLY_DELETE_WEBMENTION
            }
        }
        $job->finish('All went well!');
    });

    $app->minion->add_task(send_webmention => sub {
        my $job = shift;
        while (my $webmention = shift) {
            try {
                if ($webmention->send) {
                    $job->app->log->info(sprintf "Webmention to endpoint [%s] from [%s] sent.",
                        $webmention->target, $webmention->source);
                }
                elsif ($_->endpoint) {
                    $job->app->log->info(sprintf "Webmention to endpoint [%s] from [%s] sent,"
                        . "but no delivery confirmation recieved.",
                        $webmention->target, $webmention->source());
                }
            }
            catch {
                my $err = shift || 'unknown error';
                $job->fail(sprintf "Webmentionto endpoint [%s] from [%s] crashed: %s.",
                    $webmention->target, $webmention->source, $err);
            }
        }
        $job->finish('All went well!');
    });
}

1;