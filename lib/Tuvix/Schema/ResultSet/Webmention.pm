package Tuvix::Schema::ResultSet::Webmention;
use strict;
use warnings FATAL => 'all';
use DateTime;

use Web::Mention::Mojo;
use Mojo::URL;
use Mojo::Log;

use base 'DBIx::Class::ResultSet';

my $log = Mojo::Log->new;

sub from_webmention {
    my $self = shift;
    my $webmention = shift;

    my $webmention_author = $webmention->author;
    #    my $schema = $self->result_source->schema;

    if (!$webmention->is_verified) {
        $log->warn('Attempt to create webmention from unverified source.');
        return undef;
    }

    my $target_path = Mojo::URL
        ->new($webmention->target)
        ->path
        ->to_string;

    my $wms = $self->find_or_new(
        {
            'me.path'   => $target_path,
            'me.source' => $webmention->source(),
            'me.type'   => $webmention->type
        },
        {
            join     => 'posts',
            prefetch => 'posts' # return post data too
        }
    );

    # TODO
    $wms->status('pending');

    foreach my $attr (qw/time_received time_verified endpoint content type source/) {
        if ($attr =~ /^time_/) {
            if (!$wms->$attr) {
                $wms->$attr($webmention->$attr);
            }
        }
        else {
            $wms->$attr($webmention->$attr);
        }
    }

    if ($webmention_author) {
        foreach my $attr (qw/name url photo/) {
            my $tattr = "author_" . $attr;
            $wms->$tattr($webmention_author->$attr);
        }
    }

    return $wms;
}


1;