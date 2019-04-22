package Tuvix::ExtendedPlerd::Post;
use strict;
use warnings FATAL => 'all';

use Moose;

use base 'Plerd::Post';

sub file_type {
    '(md|markdown)';
}

has 'type' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1
);

sub _build_type {
    my $self = shift;
    return ${$self->attributes}{type} // 'post';
}

1;