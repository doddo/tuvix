package Tuvix::Schema;
use strict;
use warnings FATAL => 'all';


use base qw/DBIx::Class::Schema/;


__PACKAGE__->load_namespaces();

1;
