use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION   => '0.01',
    PREREQ_PM => {
        'Mojolicious'              => '8.07',
        'Mojo::Unicode::UTF8'      => '0.002',
        'DateTime::Format::SQLite' => '0.11',
        'DBIx::Class::Core'        => '0.082841',
        'DBIx::Class::Schema'      => '0',
        'Moose'                    => '2.2011',
        'Plerd'                    => '0',
        'SQL::Translator'          => '0.11024',
        'File::ChangeNotify'       => '0.29'
    },
    test      => { TESTS => 't/*.t' }
);
