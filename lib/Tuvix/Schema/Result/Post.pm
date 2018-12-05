package Tuvix::Schema::Result::Post;
use base qw/DBIx::Class::Core/;


use strict;
use warnings FATAL => 'all';
__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('posts');
__PACKAGE__->add_columns(qw/guid title body author_name uri/);
__PACKAGE__->add_columns(date => { data_type => 'DateTime' });
__PACKAGE__->add_columns(description => { is_nullable => 1 });
__PACKAGE__->set_primary_key('guid');
__PACKAGE__->add_unique_constraint( ['uri'] );

__PACKAGE__->has_many(comments => 'Tuvix::Schema::Result::Comment', 'guid');

sub newer_post {

}

sub older_post {

}


1;
