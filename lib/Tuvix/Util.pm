package Tuvix::Util;
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;
use File::Basename qw/basename dirname/;
use File::Copy qw(copy);
use File::Spec::Functions 'catdir';

our @ISA = qw(Exporter);
our @EXPORT = qw(mkdir_p cp_r);


sub mkdir_p {
    my %args = @_;

    exists $args{target} or croak "missing mandatory arg: $_\n"
        for qw/target/;

    my $verbose = $args{verbose} // 0;
    my $noop = $args{noop} // 0;

    my @dirs;
    my $dirname = $args{target};
    push @dirs, $dirname;

    while ($dirname = dirname($dirname)) {
        last if $dirname eq $dirs[0];
        unshift @dirs, $dirname;
    }

    foreach my $dir (@dirs) {
        if (!-d $dir) {
            if (-e $dir) {
                cluck(sprintf "could not create %s: This file %s was in the way and it was not a dir.",
                    $args{target}, $dir);
            }
            elsif (!-d $dir) {

                if ($verbose) {
                    printf "creating directory '%s'.\n", $dir;
                }
                unless ($noop) {
                    mkdir($dir) or croak "Unable to create dir $dir:$!\n";
                }
            }
        }
    }

    return @dirs;
}


sub cp_r {
    my %args = @_;
    my $_cp_r;
    my @targets;
    exists $args{$_} or croak "missing mandatory arg: $_\n"
        for qw/source target/;

    my $verbose = $args{verbose} // 0;
    my $noop = $args{noop} // 0;
    my $maxdepth = $args{maxdepth} // 1000;

    $_cp_r = sub {
        my $source = shift;
        my $target = shift;
        my $depth = shift || 0;

        return @targets if (++$depth > $maxdepth);

        if (-d $source) {

            opendir(my $dh, $source) or croak "unable to open directory $source: $!\n";


            # If you do cp_r (src => 'assets/kalle' dst => 'assets/kula'
            # and assets/kalle  is a dir, then it is implied that:
            # if assets/kula ends without a slash, that the contents of
            # assets/kalle should be copied to assets/kula
            # rather than assets/kula/kalle
            # whereas if you end name with / (dst => assets/kula/), it's
            # the other way around.
            my $rel_target = ($depth == 1 && $target !~ m{/$})
                ? $target
                : catdir($target, basename($source));

            if (! -d  $rel_target) {
                mkdir_p(
                    target  => $rel_target,
                    verbose => $verbose,
                    noop    => $noop
                )
            }

            while (my $filename = readdir $dh) {
                next if ($filename eq '.' || $filename eq '..');

                $_cp_r->(catdir($source, $filename), $rel_target, $depth);
            }
            closedir($dh);
        }
        else {
            my $relative_target = catdir($target, basename($source));
            if ($verbose) {
                printf "Copying '%s' => '%s'...\n", $source, $relative_target;
            }
            if (! -e $relative_target){
                unless ($noop) {
                    copy($source, $relative_target) or croak "Unable to copy $source => $relative_target: $!\n";
                }
                push @targets, [$source, $relative_target];
            }
            else {
                # TODO: replace capabilities.
                # unlink, copy, and / or die if it's a dir?
                croak "Unable to copy $source => $relative_target: File exists.\n";
            }
        }
        return @targets;
    };

    if (! -d  $args{target}) {
        mkdir_p(
            target  => $args{target},
            verbose => $verbose,
            noop    => $noop
        )
    }

    return $_cp_r->($args{source}, $args{target});
}

1;