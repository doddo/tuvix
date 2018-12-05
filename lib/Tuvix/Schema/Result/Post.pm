package Tuvix::Schema::Result::Post;
use base qw/DBIx::Class::Core/;
use Mojo::Unicode::UTF8;
use Mojo::Util qw(url_escape);


use strict;
use warnings FATAL => 'all';
__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('posts');
__PACKAGE__->add_columns(qw/guid title body author_name/);
__PACKAGE__->add_columns( date => { data_type => 'DateTime' } );
__PACKAGE__->add_columns( description => { is_nullable => 1} );
__PACKAGE__->set_primary_key('guid');
__PACKAGE__->has_many(comments => 'Tuvix::Schema::Result::Comment', 'guid');

sub uri {
    my $self = shift;
    join '/', ('/post', $self->date->ymd, url_escape($self->title));
}

sub newer_post {

}

sub older_post {

}



1;
