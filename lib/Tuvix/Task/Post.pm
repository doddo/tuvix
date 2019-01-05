package Tuvix::Task::Post;

use strict;
use warnings FATAL => 'all';

use Try::Tiny;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(publish_post => sub {
        my $job = shift;
        my $post = shift;

        $job->app->log->info('Processing incoming webmention from: ' . $webmention->source);
        try {
            $webmention->verify()
        }
        catch {
            my $err = shift || 'unknown error';
            $job->fail('Invalid webmention from: %s to %s: %s ',
                $webmention->source, $webmention->target, $err);
        };

        $job->finish('All went well!');

    });
}

    1;