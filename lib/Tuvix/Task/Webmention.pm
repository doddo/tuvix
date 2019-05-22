package Tuvix::Task::Webmention;
use strict;
use warnings FATAL => 'all';

use Web::Mention::Mojo;
use Data::Dumper;

use JSON;

use Try::Tiny;
use Mojo::Base 'Mojolicious::Plugin';

use JSON;

my $json = JSON->new->convert_blessed;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(receive_webmention => sub {
        my ($job, $wm_serialized) = @_;

        my $webmention;

        try {
            $webmention = Web::Mention::Mojo
                ->FROM_JSON($json->decode($wm_serialized));
        }
        catch {
            my $err = shift || 'unknown error';
             $job->fail("Unable to deserialize webmention from:[%s] error: [%s].",  Dumper($wm_serialized), $err)
        };

        $app->log->info(sprintf('Processing incoming webmention from: [%s] to [%s].',
            $webmention->source, $webmention->target));

        if ($app->can('ua') && $app->ua) {
            # So that it can be tested, but also so that custom settings can be provided
            # such like user agent and timeouts usw.
            $app->log->debug(sprintf('Setting UA for  webmention from: [%s]', $webmention->source));

            $webmention->ua($app->ua)
        }

        $app->log->info('Processing incoming webmention from: ', $webmention->source);
        try {
            $webmention->verify()
        }
        catch {
            my $err = shift || 'unknown error';
            $job->fail(sprintf('Invalid webmention from: [%s] to [%s] (endpoint [%s]): %s ',
                $webmention->source, $webmention->target, $webmention->endpoint || "unknown", $err));
        };

        if ($webmention->is_verified) {
            $job->app->log->debug(sprintf('Webmention of type "%s" from: [%s] to [%s] is verifed.',
                $webmention->type, $webmention->source, $webmention->target));

            if (my $wm = $job->app->schema->resultset('Webmention')->from_webmention($webmention)) {
                if (!$wm->in_storage || !$wm->is_changed) {
                    try {
                        # TODO: add shitlist filter here
                        $wm->insert_or_update();

                        my $msg = sprintf('Webmention of type "%s" from: [%s] to [%s] is successfully added.',
                            $webmention->type, $webmention->source, $webmention->target);
                        $job->app->log->info($msg);
                        $job->finish($msg);
                    }
                    catch {
                        my $err = shift || "Unknown error";
                        $job->fail(sprintf('Cannot save webmention from: [%s] to [%s] in the DB: %s ',
                            $webmention->source, $webmention->target, $err));
                    }
                }
            }
            else {
                $job->fail(sprintf('verified Webmention of type "%s" from [%s] to [%s] cannot be created.',
                    $webmention->source, $webmention->target));
            }
        }
        else {
            # TODO: handle
            $job->app->log->info(sprintf 'Not able to verify webmention from, maybe a delete: %s to %s.',
                $webmention->source, $webmention->target);
            # SOMETHING->POSSIBLY_DELETE_WEBMENTION
        }

        $job->finish('All went well!');
    });
}

1;