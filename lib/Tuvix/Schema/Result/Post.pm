package Tuvix::Schema::Result::Post;

use base qw/DBIx::Class::Core/;

use strict;
use warnings FATAL => 'all';

use Moose;
use Mojo::URL;

has 'newer_post' => (
    isa        => 'Maybe[Tuvix::Schema::Result::Post]',
    is         => 'ro',
    lazy_build => 1
);

has 'older_post' => (
    isa        => 'Maybe[Tuvix::Schema::Result::Post]',
    is         => 'ro',
    lazy_build => 1
);

has 'uri' => (
    isa        => 'Mojo::URL',
    is         => 'ro',
    lazy_build => 1
);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('posts');
__PACKAGE__->add_columns(qw/guid title body author_name path source_file/);
__PACKAGE__->add_columns(date => { data_type => 'DateTime' });
__PACKAGE__->add_columns(description => { is_nullable => 1 });
__PACKAGE__->set_primary_key('guid');
__PACKAGE__->add_unique_constraint([ 'path' ]);
__PACKAGE__->add_unique_constraint([ 'source_file' ]);

__PACKAGE__->has_many(comments => 'Tuvix::Schema::Result::Comment', 'guid');
__PACKAGE__->has_many(webmentions => 'Tuvix::Schema::Result::Webmention', 'guid');

__PACKAGE__->resultset_class('Tuvix::Schema::ResultSet::Post');



sub _build_newer_post {
    my $self = shift;

    my $schema = $self->result_source->schema;
    my $rs = $schema->resultset('Post')->search(
        {
            date => { '>=' => $self->get_column('date') },
            guid => { '!=' => $self->get_column('guid') }
        },
        {
            order_by => { -asc => qw/date/ },
            limit    => 1
        }
    );
    return $rs->next;
}

sub _build_older_post {
    my $self = shift;
    my $schema = $self->result_source->schema;
    my $rs = $schema->resultset('Post')->search(
        {
            date => { '<=' => $self->get_column('date') },
            guid => { '!=' => $self->get_column('guid') }
        },
        {
            order_by => { -desc => qw/date/ },
            limit    => 1
        }
    );
    return $rs->next;
}

sub _build_uri {
    return Mojo::URL->new("/posts/")->path(shift->path());
}

1;
