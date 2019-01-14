package Web::Mention::Mojo;
use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Log;

use Tuvix::TypeConstraints;
use Web::Microformats2::Parser;

use Try::Tiny;

use Mojo::Util qw\url_escape\;

use HTTP::Link;

extends 'Web::Mention';


# ¯\_(ツ)_/¯
*Mojo::URL::eq = sub {
    return shift->to_abs->to_string eq
        shift->to_abs->to_string;
};

*Mojo::URL::as_string = sub {
    return shift->to_abs->to_string;
};

has 'error' => (
    isa => 'Maybe[HashRef]',
    is  => 'rw'
);

has 'log' => (
    isa     => 'Mojo::Log',
    is      => 'rw',
    default => sub {Mojo::Log->new()}
);

class_has '+ua' => (
    isa     => 'Mojo::UserAgent',
    is      => 'rw',
    default => sub {Mojo::UserAgent->new}
);

has '+target' => (
    isa      => 'URL',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has '+source' => (
    isa      => 'URL',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has '+endpoint' => (
    isa      => 'Maybe[URL]',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has '+original_source' => (
    isa        => 'URL',
    is         => 'ro',
    lazy_build => 1,
    coerce     => 1,
);


sub verify {
    my $self = shift;

    $self->is_tested(1);
    my $response = $self->ua->get($self->source);

    # Search for both plain and escaped ("percent-encoded") versions of the
    # target URL in the source doc. We search for the latter to account for
    # sites like Tumblr, who treat outgoing hyperlinks as weird internally-
    # pointing links that pass external URLs as query-string parameters.
    if (($response->result->body =~ $self->target)
        || ($response->result->body =~ url_escape($self->target))
    ) {
        $self->time_verified(DateTime->now);
        $self->source_html($response->result->body);
        $self->_clear_mf2;
        $self->_clear_content;
        $self->_clear_author;
        $self->log->debug(sprintf "Verified webmention. Source:[%s] Target:[%s] Endpoint:[%s]",
            $self->source, $self->target, $self->endpoint);
        return 1;
    }
    else {
        return 0;
    }
}

sub _build_source_mf2_document {
    my $self = shift;

    return unless $self->is_verified;
    my $doc;
    try {
        my $parser = Web::Microformats2::Parser->new;
        $doc = $parser->parse(
            $self->source_html,
            url_context => $self->source->to_string);
    }
    catch {
        die "Error parsing source HTML: $_";
    };
    return $doc;
}

sub _build_endpoint {
    my $self = shift;

    my $endpoint;
    my $source = $self->source;
    my $target = $self->target;

    # Is it in the Link HTTP header?
    my $response = $self->ua->get($target);
    my $headers = $response->res->can('headers')
        ? $response->res->headers
        : undef;

    if ($headers && $headers->can('link') && $headers->link) {
        my @header_links = HTTP::Link->parse($headers->link);
        foreach (@header_links) {
            if ($_->{relation} eq 'webmention') {
                $endpoint = $_->{iri};
            }
        }
    }

    # Is it in the HTML?
    unless ($endpoint) {
        $self->log->debug("No webmention link found in the Target headers of:", $target);
        if ($headers && $headers->can('content_type') && $headers->content_type =~ m{^text/html\b}) {
            my $dom = Mojo::DOM58->new($response->res->content->get_body_chunk);
            my $nodes_ref = $dom->find(
                'link[rel~="webmention"], a[rel~="webmention"]'
            );
            for my $node (@$nodes_ref) {
                $endpoint = $node->attr('href');
                last if defined $endpoint;
            }
        }
    }

    # TODO make sure that the URL is an absolute one
    return defined $endpoint
        ? Mojo::URL->new($endpoint)->to_abs
        : undef

}

sub send {
    my $self = shift;

    my $endpoint = $self->endpoint;
    my $source = $self->source;
    my $target = $self->target;

    unless ($endpoint) {
        return 0;
    }

    # Step three: send the webmention to the target!
    my $response = $self->ua->post(
        $self->endpoint => { 'Content-Type' => 'application/x-www-form-urlencoded' } => "source=$source&target=$target"
    );

    $self->error($response->res->error);

    return !$response->res->error;
}


=pod

=encoding utf-8

=head1 NAME

Web::Mention::Mojo

=head1 DESCRIPTION

This is a subclass of Web::Mention by Jason McIntosh (http://jmac.org).

That's to make it work with L<Mojo::UserAgent> in stead of L<LWP::UserAgent>.

There've been a whole bottle of glue poured over it.
And some duct tape.

The functions which did not like the Mojo::UserAgent out of the box, like
_build_endpoint and _build_source_mf2_document and verify have been lifted over
from Web::Mention (c) Jason McIntosh and then modified to work, and then put in
this new box.

It's all to make tests run swiftly with L<Mojo::Test>. Not only of the sending end,
but also the recieving one. - all can be tested in one fell swoop.


So great.


¯\_(⊙_ʖ⊙)_/¯

It will do for now.


=cut


1;