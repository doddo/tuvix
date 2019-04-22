package Tuvix::PlerdHelper;
use strict;
use warnings;
use feature qw\say\;

use Data::GUID;

use Moose;
use Mojo::Log;
use Mojo::URL;
use Mojo::Unicode::UTF8;
use Mojo::Util qw(slugify);

use Try::Tiny;
use Tuvix::Schema;

has 'db' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1
);

has 'base_path' => (
    is      => 'ro',
    isa     => 'Mojo::URL',
    # TODO app->routes->lookup( 'posts' )
    default => sub {Mojo::URL->new()->path('/posts/')}
);

has 'db_opts' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
);

has 'log' => (
    is      => 'ro',
    isa     => 'Mojo::Log',
    default => sub {Mojo::Log->new}
);

has 'plerd' => (
    is      => 'ro',
    isa     => 'Tuvix::ExtendedPlerd',
    default => sub {{}}
);

has 'schema' => (
    is         => 'rw',
    isa        => 'Tuvix::Schema',
    lazy_build => 1
);

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

    $self->log->info(sprintf "Creating or updating post [%s]: %s", $plerd_post->guid, $plerd_post->title);

    my $post = $schema->resultset('Post')->find_or_new(
        {
            guid        => $plerd_post->guid(),
            source_file => $plerd_post->source_file->basename()
        },
    );

    $plerd_post->description($plerd_post->stripped_body);

    $post->title($plerd_post->title());
    $post->body($plerd_post->body());
    $post->date($plerd_post->date());

    if ($plerd_post->can('type')){
        $post->type($plerd_post->type());
    }

    #$post->source_file($plerd_post->source_file->basename);

    $post->description($plerd_post->description());
    $post->author_name($plerd_post->plerd->author_name());

    unless ($post->path()) {
        # Find a name which is not allocated already ...


        my $post_slug = join '-', ($post->date->ymd, slugify($plerd_post->title, 1));
        my $path = $self->base_path->path->merge($post_slug)->to_string;
        my $path_base = $path;
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
    my $source_file = shift;

    $self
        ->schema
        ->resultset('Post')
        ->search({ source_file => $source_file })
        ->delete;
}

sub publish_all {
    my $self = shift;
    my $schema = $self->schema;
    my $plerd = $self->plerd;

    my $atomic_publish = sub {
        my @ids = map {$_->guid()->as_string => $_} @{$plerd->posts};

        # Delete all that is present already
        $schema->resultset('Post')->search(
            { guid => { -not_in => \@ids } }
        )->delete;

        for my $plerd_post (@{$plerd->posts}) {
            $self->create_or_update_post($plerd_post, $schema)
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

        if ($error) {
            die "Could not preform transaction ADN rollback failed.\n"
                if ($error and $error =~ /Rollback failed/);
            die "Unexpected error encoutered: $error\n";
        }

        die "Unable to preform transaction\n";
    };
    return $rs
}

sub _build_schema {
    my $self = shift;
    return Tuvix::Schema
        ->connect(@{$self->db}, $self->db_opts);
}

1;