package Tuvix::WebmentionTransmitter;
use strict;
use warnings FATAL => 'all';

use Moose;
use Mojo::URL;
use Carp;


use Web::Mention;

has 'base_uri' => (
    isa      => 'Mojo::URL',
    is       => 'ro',
    required => 1,
);

has 'log' => (
    is      => 'ro',
    isa     => 'Mojo::Log',
    default => sub {Mojo::Log->new}
);


sub send_webmentions {
    my $self = shift;
    my $post = shift;
    unless ($post->isa('Tuvix::Schema::Result::Post')) {
        cluck(sprintf("Input argument was not a 'Tuvix::Schema::Result::Post' as expected but a %s\n",
            ref $post));
        return;
    }

    my $source_uri = $self
        ->base_uri
        ->path($post->path);

    my @wms = Web::Mention->new_from_html(
        source => $source_uri->to_abs->to_string,
        html   => $post->body,
    );

    my %report = (
        attempts  => 0,
        delivered => 0,
        sent      => 0,
    );
    foreach (@wms) {
        $report{attempts}++;
        if ($_->send) {
            $self->log->info(sprintf "Sent webmention to endpoint [%s] from [%s] %s",
                $_->target, $post->guid(), $post->title);
            $report{delivered}++;
        }
        elsif ($_->endpoint) {
            $self->log->info(sprintf "Sent webmention (but delivery was not confirmed) to endpoint [%s] from [%s] %s",
                $_->target, $post->guid(), $post->title);
            $report{sent}++;
        }
    }

    return(\%report);
}

1;