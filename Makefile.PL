use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION   => '0.01',
    PREREQ_PM => {
        'Mojolicious'                          => '8.07',
        'Mojo::Unicode::UTF8'                  => '0.002',
        'DateTime::Format::SQLite'             => '0.11',
        'DBD::SQLite'                          => '1.60',
        'DBIx::Class'                          => '0.082841',
        'DBIx::Class::Core'                    => '0',
        'DBIx::Class::Schema'                  => '0',
        'Moose'                                => '2.2011',
        'Text::MultiMarkdown'                  => '1.000035',
        'Plerd'                                => '1.802',
        'Tie::Hash::Expire'                    => '0.03',
        'SQL::Translator'                      => '0.11024',
        'File::ChangeNotify'                   => '0.29',
        'File::Temp'                           => '0',
        'File::Copy'                           => '0',
        'Minion::Backend::SQLite'              => '4.002',
        'Mojolicious::Plugin::Minion::Workers' => '0',
        'Web::Mention'                         => '0'
    },
    test      => { TESTS => 't/*.t' }
);
