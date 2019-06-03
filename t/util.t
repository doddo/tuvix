#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;

use File::Spec::Functions 'catdir';

use feature qw/say/;

plan tests => 12;

BEGIN {
    unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
    use_ok("Tuvix::Util", qw/cp_r mkdir_p/);
}


my @expected_dirs = qw{/ /tmp /tmp/some /tmp/some/directories};
my @expected_dirs2;
my $test_dir = "$FindBin::Bin/slask/util";
my $test_src = "$FindBin::Bin/assets/util";
unshift(@expected_dirs2, catdir($test_dir, $_)) for @expected_dirs;
my @expected_cp_files = (
    [
        catdir($test_src, "some_test_file.txt"),
        catdir($test_dir, "some_test_file.txt")
    ],
    [
        catdir($test_src, "test/nested_test_file.txt"),
        catdir($test_dir, "test/nested_test_file.txt"),
    ]
);

ok(my @dirs = mkdir_p(
    target => '/tmp/some/directories',
    noop   => 1
), "noop mkdir_p does not crash.");

is_deeply(\@dirs, \@expected_dirs, "mkdir_p create the correct dir structure in order");

ok(mkdir_p(
    target => $expected_dirs2[0],
), "mkdir_p does not crash.");

foreach my $dir (@expected_dirs2) {
    last if ($dir eq $test_dir);
    ok(-d $dir, "$dir got created and is a directory.");
}

ok(my @targets = cp_r(
    source  => $test_src,
    target  => "$FindBin::Bin/slask",
    noop    => 1,
    verbose => 1
), "noop cp_r does not crash.");

is_deeply(\@targets, \@expected_cp_files, 'Correct files would have been copied recursively');

ok(cp_r(
    source  => $test_src,
    target  => "$FindBin::Bin/slask",
    verbose => 1
), "cp_r does not crash.");

ok(-e $_->[1], "file $_->[0] got copied  to $_->[1]") for @expected_cp_files;

done_testing();

END {
    foreach my $file_pairs (@expected_cp_files) {
        die unless $file_pairs->[1] =~ m/slask/;
        unlink $file_pairs->[1];


    }

    foreach my $dir (@expected_dirs2) {
        last if ($dir eq $test_dir);
        rmdir $dir or warn "could not remove test dir $dir: $!";
    }
}