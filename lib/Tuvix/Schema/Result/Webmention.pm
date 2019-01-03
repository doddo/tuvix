package Tuvix::Schema::Result::Webmention;
use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('webmention');

# 'type' => (
#     isa => Enum[qw(rsvp reply like repost quotation mention)],

__PACKAGE__->add_columns(qw/type path source status/);

__PACKAGE__->add_columns(
    time_recieved => { data_type => 'DateTime' },
    time_verified => { data_type => 'DateTime' },
);
__PACKAGE__->add_columns(
    author_webpage => { is_nullable => 1 },
    endpoint       => { is_nullable => 1 },
    content        => { is_nullable => 1 },
);

__PACKAGE__->add_columns(
    author_webpage => { is_nullable => 1 },
    author_email   => { is_nullable => 1 },
    author_name    => { is_nullable => 1 },
);

__PACKAGE__->add_unique_constraint([ qw(path source type) ]);

# Webmention "target" maps to a post Path.
__PACKAGE__->belongs_to('post' => 'Tuvix::Schema::Result::Post', 'path');

1;
