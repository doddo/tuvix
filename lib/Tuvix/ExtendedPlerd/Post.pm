package Tuvix::ExtendedPlerd::Post;
use strict;
use warnings FATAL => 'all';

use Moose;

use base 'Plerd::Post';

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