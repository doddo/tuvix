package Tuvix::ExtendedPlerd::Post;
use strict;
use warnings FATAL => 'all';

use Moose;

use Web::Mention::Mojo;

use base 'Plerd::Post';

sub file_type {
    '(md|markdown)';
}

has 'type' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1
);

sub send_webmentions {
    my $self = shift;

    my @wms = Web::Mention::Mojo->new_from_html(
        source => $self->uri->as_string,
        html => $self->body,
    );

    my %report = (
        attempts => 0,
        delivered => 0,
        sent => 0,
    );
    foreach ( @wms ) {
        $report{attempts}++;
        if ( $_->send ) {
            $report{delivered}++;
        }
        if ( $_->endpoint ) {
            $report{sent}++;
        }
    }

    return (\%report);
}


sub _build_type {
    my $self = shift;
    return ${$self->attributes}{type} // 'post';
}


=pod

=encoding utf-8

=head1 NAME

Tuvix::ExtendedPlerd::Post

=head1 DESCRIPTION

This is a subclass of Plerd::Post by Jason McIntosh (http://jmac.org).

It's got the file_type method, with which it can be hooked into the publishing logic as if it were
any extension for tuvix.

Also, for sending of webmentions, it's using the L<Web::Mention::Mojo> subclass of L<Web::Mention>,
which uses L<Mojo::UserAgent> in stead of L<LWP::UserAgent>. This is better because it's a Mojolicious app, and
the tests can be conducted easier with that, and it allows sending webmentions to the loopback address, which also
is a great help when testing the stuff.

¯\_(⊙_ʖ⊙)_/¯


=cut




1;