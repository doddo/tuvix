package Tuvix::Schema::Result::Webmention;
use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('webmention');

# 'type' => (
#     isa => Enum[qw(rsvp reply like repost quotation mention)],

# 'status' => (
#     isa => Enum[qw(pending approved rejected)],

__PACKAGE__->add_columns(
    type            => { is_nullable => 0 },
    path            => { is_nullable => 0 },
    source          => { is_nullable => 0 },
    original_source => { is_nullable => 0 },
    status          => { is_nullable => 0 },
    time_received   => { data_type => 'DateTime' },
    time_verified   => { data_type => 'DateTime' },
    endpoint        => { is_nullable => 1 },
    content         => { is_nullable => 1 },
    author_name     => { is_nullable => 1 },
    author_url      => { is_nullable => 1 },
    author_photo    => { is_nullable => 1 },
);

__PACKAGE__->add_columns("id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 });

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(path_source_type => [ qw(path source type) ]);

# Webmention "target" maps to a post Path.
__PACKAGE__->belongs_to('posts' => 'Tuvix::Schema::Result::Post', 'path');

# Result source with some nifty helpers!
__PACKAGE__->resultset_class('Tuvix::Schema::ResultSet::Webmention');

sub get_post {
    my $self = shift;
    my $schema = $self->result_source->schema;
    my $rs = $schema->resultset('Post')->search(
        {
            'path' => $self->get_column('path')
        }
    );
    return $rs->next;

}

1;
