package Tuvix::PlerdHelper;
use strict;
use warnings;
use feature qw\say\;

use Data::GUID;

use Moose;
use Mojo::Unicode::UTF8;
use Mojo::Util qw(slugify);

use Try::Tiny;
use Tuvix::Schema;

has 'db' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1
);

has 'db_opts' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
);

has 'plerd' => (
    is      => 'ro',
    isa     => 'Plerd',
    default => sub {{}}
);

sub schema {
    my $self = shift;
    return Tuvix::Schema
        ->connect(@{$self->db}, $self->db_opts);
}

sub deploy_schema {
    my $self = shift;
    my $drop_table = shift || 0;

    $self
        ->schema
        ->deploy({ add_drop_table => $drop_table });
}

sub create_or_update_post {
    my $self = shift;
    my $plerd_post = shift;
    my $schema = shift || $self->schema();

    my $post = $schema->resultset('Post')->find_or_new(
        { guid => $plerd_post->guid() },
    );

    $plerd_post->description($plerd_post->stripped_body);

    $post->title($plerd_post->title());
    $post->body($plerd_post->body());
    $post->date($plerd_post->date());
    $post->source_file($plerd_post->source_file->basename);

    $post->description($plerd_post->description());
    $post->author_name($plerd_post->plerd->author_name());

    unless ($post->path()) {
        # Find a name which is not allocated already ...
        my $path_base = join '-', ($post->date->ymd, slugify($plerd_post->title, 1));
        my $path = $path_base;
        my $i = 0;
        while ($schema->resultset('Post')->find({ path => $path })) {
            $path = sprintf '%s-%i', $path_base, $i++
        }
        $post->path($path);
    }
    # Save this here so we cam send properly formatted webmentions
    $plerd_post->published_filename($post->path());

    #printf "%-50.48s %s\n", $post->title(), $post->path();
    return $post->update_or_insert;
}

sub delete_post_from_filename {
    my $self = shift;
    my $source_filename = shift;

    $self
        ->schema
        ->resultset('Post')
        ->search({ source_filename => $source_filename })
        ->delete;
}

sub publish_all {
    my $self = shift;
    my $schema = $self->schema;
    my $plerd = $self->plerd;
    my @published_posts;

    my $atomic_publish = sub {
        my @ids = map {$_->guid()->as_string => $_} @{$plerd->posts};

        # Delete all that is present already
        $schema->resultset('Post')->search(
            { guid => { -not_in => \@ids } }
        )->delete;

        for my $plerd_post (@{$plerd->posts}) {
            push @published_posts, $self->create_or_update_post($plerd_post, $schema)
        }

        return $schema->resultset('Post');
    };

    my $rs;

    try {
        $rs = $schema->txn_do($atomic_publish);
    }
    catch {
        # Transaction failed
        my $error = shift;

        die "Could not preform transaction ADN rollback failed.\n"
            if ($error and $error =~ /Rollback failed/);

        die "Unable to preform transaction\n";
    };
    return $rs

}

1;