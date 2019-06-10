#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Mojolicious::Lite;
use Mojo::Unicode::UTF8;

use File::Temp qw/tempfile :seekable/;
use File::Copy;

use FindBin;

BEGIN {unshift @INC, ("$FindBin::Bin/lib", "$FindBin::Bin/../lib")}

use Tuvix::Watcher;
use Tuvix::Schema;

plan tests => 7;

plugin 'Config' => { file => $FindBin::Bin . '/assets/tuvix.conf' };

my $watcher_pidfile = File::Temp->new(SUFFIX => '.pid');
my $temporary_database = File::Temp->new(SUFFIX => '.db');

my @db_cx = ("dbi:SQLite:${temporary_database}", "", "");
@{${app->config}{'db'}} = @db_cx;
${app->config}{'watch_source_dir'} = 1;

my $dbh = Tuvix::Schema
    ->connect(@db_cx,
    { RaiseError => 1, sqlite_unicode => 1 });

$dbh->deploy({ add_drop_table => 1 });

my $draft_file_s = ${app->config}{'source_path'} . '/../drafts/draft.markdown';
my $draft_file_t = ${app->config}{'source_path'} . '/draft.markdown';
my $draft_file_t_new_loc = ${app->config}{'source_path'} . '/draft_new_loc.markdown';

my $pid;

{
    my $i = 0;

    chdir "$FindBin::Bin";

    ${app->config}{'watcher_pidfile'} = $watcher_pidfile->filename;

    my $watcher = Tuvix::Watcher->new(config => app->config);
    $pid = $watcher->start();

    ok($pid, "forked a new directory watcher process (with pid $pid)");

    my $watcher2 = Tuvix::Watcher->new(config => app->config);
    my $pid2 = $watcher->start(config => app->config);

    ok(!$pid2, 'second instance does not get a lock');

    my $posts = $dbh->resultset('Post');

    # Give the watcher some time to start watching...
    # TODO do something proper later
    sleep 4;

    copy($draft_file_s, $draft_file_t) or die $!;

    while (!$posts->find({ source_file => 'draft.markdown' })
        && $i++ < 10) {
        sleep 1;
    }
    ok(my $post_orig = $posts->find({ source_file => 'draft.markdown' }),
        "draft is published when file is created in source_path");

    rename $draft_file_t, $draft_file_t_new_loc;

    while (!$posts->find({ source_file => 'draft_new_loc.markdown' })
        && $i++ < 10) {
        sleep 1;
    }

    ok(my $post_new = $posts->find({ source_file => 'draft_new_loc.markdown' }),
        "Draft is republished when file is renamed in source_path");

    cmp_ok($post_orig->guid, 'eq', $post_new->guid,
        "Post republished with same guid: " . $post_new->guid);

    ok(!$posts->find({ source_file => 'draft.markdown' }),
        "Original post source_file with old name does not exist after having been moved");

    unlink $draft_file_t_new_loc;

    while ($posts->find({ source_file => 'draft_new_loc.markdown' })
        && $i-- > 0) {
        sleep 1;
    }
    ok(!$posts->find({ source_file => 'draft_new_loc.markdown' }),
        "draft is unpublished when file is removed from source_path");

}

done_testing();

END {
    unlink $draft_file_t;
    unlink $watcher_pidfile;
    unlink $temporary_database;
    kill 'TERM', $pid;
}
