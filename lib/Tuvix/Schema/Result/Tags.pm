package Tuvix::Schema::Result::Tags;
use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('tags');

__PACKAGE__->add_columns(qw/guid tag url_escaped/);

__PACKAGE__->add_unique_constraint([qw( guid tag )]);

__PACKAGE__->belongs_to('post' => 'Tuvix::Schema::Result::Post', 'guid');


1;