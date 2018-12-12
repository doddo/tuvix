#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;

BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use Mojo::Unicode::UTF8;
use Mojolicious::Lite;

use Plerd;
use Plerd::Util;

use Try::Tiny;
use Tuvix;
use Tuvix::PlerdHelper;
use Tuvix::Schema;

use feature qw/say/;

use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use Pod::Usage qw/pod2usage/;

my $drop_tables = 0;
my $help = 0;
my $send_webmentions = 0;
my $config_file = "$FindBin::Bin/../tuvix.conf";

GetOptions("drop_tables" => \$drop_tables,
    "help"               => \$help,
    "send-webmentions"   => \$send_webmentions,
    "config-file=s"      => \$config_file)
    or pod2usage(-exitval => 2, -verbose => 1);

pod2usage(-exitval => 0, -verbose => 1) if $help;

die (sprintf "Unable to locate config file '%s'", $config_file)
    unless (-e $config_file);

plugin 'Config' => { file => $config_file };
plugin 'DefaultHelpers';

my $config_ref = app->config('plerd');

my $plerd = Plerd->new($config_ref);

my $ph = Tuvix::PlerdHelper->new(
    db      => \@{app->config('db')},
    db_opts => app->config('db_opts'),
    plerd   => $plerd
);

$ph->deploy_schema($drop_tables);

my $posts = $ph->publish_all;

while (my $post = $posts->next) {
    printf "%-50.48s %s\n", $post->title(), $post->path();
}

# TODO
if ($send_webmentions){
    #$_->process_webmentions() for @{$plerd{posts};
}

1;

__END__
=encoding utf-8

=head1 NAME

plerdall_db.pl - Publish all posts from source_dir to the db.

=head1 SYNOPSIS

plerdall_db.pl  [option ...]

 Options:
   --config-file       Path to the tuvix.conf file
   --drop-tables       Drop tables when deploying the schema
   --send-webmentions  Send webmentions from posts if applicable
   --help              brief help message

=head1 OPTIONS

=over 4

=item B<--help>

Print a brief help message and exits.

=item B<--config-file>

Path to the tuvix.conf config file.

=item B<--drop-tables>

Wether to drop the db tables before deploying the schema or not.

=item B<--send-webmentions>

If a published post contains webmentions, this param specifies whether plerd should attempt to send them out or not

=back

=cut
