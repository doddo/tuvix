package Tuvix::TypeConstraints;
use strict;
use warnings FATAL => 'all';

use Mojo::URL;

use Moose::Util::TypeConstraints;

subtype 'URL'
    => as 'Object'
    => where {$_->isa('Mojo::URL')};

coerce 'URL'
    => from 'Str'
    => via {Mojo::URL->new($_)};

1;