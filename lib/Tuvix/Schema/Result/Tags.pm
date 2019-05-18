package Tuvix::Schema::Result::Tags;
use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('tags');

__PACKAGE__->add_columns(qw/guid tag url_escaped/);

__PACKAGE__->add_unique_constraint([qw( guid tag )]);

__PACKAGE__->belongs_to('post' => 'Tuvix::Schema::Result::Post', 'guid');

__PACKAGE__->add_columns("id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 });

__PACKAGE__->set_primary_key("id");


1;