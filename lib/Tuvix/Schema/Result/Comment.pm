package Tuvix::Schema::Result::Comment;
use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('comments');

__PACKAGE__->add_columns(qw/guid comment type author_name author_email status/);
__PACKAGE__->add_columns(date => { data_type => 'DateTime' });
__PACKAGE__->add_columns(author_webpage => { is_nullable => 1 });

__PACKAGE__->set_primary_key('guid');


__PACKAGE__->add_unique_constraint([qw( author_name guid comment )]);
__PACKAGE__->belongs_to('post' => 'Tuvix::Schema::Result::Post', 'guid');


1;