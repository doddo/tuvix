#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;

use FindBin;
BEGIN {unshift @INC, "$FindBin::Bin/../lib"}

use Tuvix::Model::Users;



# Make signed cookies tamper resistant
app->secrets([ 'Mojolicious rocks' ]);

helper users => sub {state $users = Tuvix::Model::Users->new()};


get '/' => sub {
    my $c = shift;

};

# Main login action
any '/auth' => sub {
    my $c = shift;

    # Query or POST parameters
    my $user = $c->param('user') || '';
    my $pass = $c->param('pass') || '';

    # Check password and render "index.html.ep" if necessary
    return $c->render unless $c->users->check($user, $pass);

    # Store username in session
    $c->session(user => $user);

    # Store a friendly message for the next page in flash
    $c->flash(message => 'Thanks for logging in.');

    # Redirect to protected page with a 302 response
    $c->redirect_to('protected');
}       => 'index';

# Make sure user is logged in for actions in this group
group {
    under sub {
        my $c = shift;

        # Redirect to main page with a 302 response if user is not logged in
        return 1 if $c->session('user');
        $c->redirect_to('index');
        return undef;
    };

    # A protected page auto rendering "protected.html.ep"
    get '/protected';
};

# Logout action
get '/logout' => sub {
    my $c = shift;

    # Expire and in turn clear session automatically
    $c->session(expires => 1);

    # Redirect to main page with a 302 response
    $c->redirect_to('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
%= form_for index => begin
  % if (param 'user') {
    <b>Wrong name or password, please try again.</b><br>
  % }
  Name:<br>
  %= text_field 'user'
  <br>Password:<br>
  %= password_field 'pass'
  <br>
  %= submit_button 'Login'
% end

@@ protected.html.ep
% layout 'default';
% if (my $msg = flash 'message') {
  <b><%= $msg %></b><br>
% }
Welcome <%= session 'user' %>.<br>
%= link_to Logout => 'logout'

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title>Login Manager</title></head>
  <body><%= content %></body>
</html>