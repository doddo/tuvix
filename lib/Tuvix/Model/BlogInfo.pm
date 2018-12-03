package Tuvix::Model::BlogInfo;
use strict;
use warnings FATAL => 'all';

use Moose;

has 'base_uri' => (
    isa      => 'Str',
    is       => 'ro',
    required => 0
);

has 'title' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'author_email' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'author_name' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'publication_path' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);


1;