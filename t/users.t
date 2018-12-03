#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use Mojolicious::Commands;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/myapp.pl";

# Allow 302 redirect responses
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

# Test if the HTML login form exists
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('form input[name="user"]')
  ->element_exists('form input[name="pass"]')
  ->element_exists('form input[type="submit"]');

# Test login with valid credentials
$t->post_ok('/' => form => {user => 'sebastian', pass => 'secr3t'})
  ->status_is(200)
  ->text_like('html body' => qr/Welcome sebastian/);

# Test accessing a protected page
$t->get_ok('/protected')->status_is(200)->text_like('a' => qr/Logout/);

# Test if HTML login form shows up again after logout
$t->get_ok('/logout')
  ->status_is(200)
  ->element_exists('form input[name="user"]')
  ->element_exists('form input[name="pass"]')
  ->element_exists('form input[type="submit"]');

done_testing();