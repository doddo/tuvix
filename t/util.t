#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;

use File::Spec::Functions 'catdir';

use feature qw/say/;


BEGIN {
    unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
    use_ok("Tuvix::Util", qw/cp_r mkdir_p/);
}


my @expected_dirs = qw{/ /tmp /tmp/some /tmp/some/directories};
my @expected_dirs2;
my @expected_dirs_with_trailing_slash;
my $test_dir = "$FindBin::Bin/slask";
my $test_src = "$FindBin::Bin/assets/util";
unshift(@expected_dirs2, catdir($test_dir, $_)) for @expected_dirs;
unshift(@expected_dirs_with_trailing_slash, catdir("$FindBin::Bin/slask/util", $_)) for @expected_dirs;


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

my @expected_cp_files_with_trailing_slash = (
    [
        catdir($test_src, "some_test_file.txt"),
        catdir($test_dir, "util/some_test_file.txt")
    ],
    [
        catdir($test_src, "test/nested_test_file.txt"),
        catdir($test_dir, "util/test/nested_test_file.txt"),
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


ok(my @targets_with_trailing_slash = cp_r(
    source  => $test_src,
    target  => "$FindBin::Bin/slask/",
    noop    => 1,
    verbose => 1
), "noop cp_r does not crash.");

is_deeply(\@targets_with_trailing_slash, \@expected_cp_files_with_trailing_slash,
    'Correct files would have been copied recursively');


ok(cp_r(
    source  => $test_src,
    target  => "$FindBin::Bin/slask",
    verbose => 1
), "cp_r does not crash.");

ok(-e $_->[1], "file $_->[0] got copied  to $_->[1]") for @expected_cp_files;


plan tests => 14;

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

    rmdir catdir($test_dir, 'test');
    rmdir $test_dir;

}