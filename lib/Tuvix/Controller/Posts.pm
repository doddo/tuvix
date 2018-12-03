package Tuvix::Controller::Posts;
use Mojo::Unicode::UTF8;

use Mojo::Base 'Mojolicious::Controller';
use Mojolicious;
use Mojo::Util qw/url_unescape/;

use Tuvix::Model::Posts;

use strict;
use warnings FATAL => 'all';

sub get_posts {
    my $self = shift;
    my $page = $self->param('page') || 1;
    my $posts_per_page = $self->param('posts_per_page') || 10;

    $self->stash(
        page  => $page,
        posts => $self->posts->get_posts_from_query(undef, $page, $posts_per_page)
    );
    $self->render(
        template => 'post'
    )
}

sub get_posts_by_title {
    my $self = shift;
    my $title = url_unescape($self->param('title'));

    $self->stash(
        posts => $self->posts->get_posts_from_query({ 'title' => $title })
    );
    $self->render(
        template => 'post'
    )
}


sub load_next {
    my $self = shift;
    $self->on(message => sub {
        my ($self, $page) = @_;
        for  my $post ($self->posts->get_posts_from_query(undef, $page)->all) {
            $self->stash(post => $post);
            $self->send($self->render_to_string(template => '_post'));
        };
    });
}

1;

__DATA__

@@ post.html.ep
% layout 'wrapper';

% for my $post (@$posts) {
<div class="post h-entry">
    <div class="title page-header"><h1><a href="[% post.uri %]"><span class="p-name">[% post.title %]</span><br /><small>[% post.month_name %] [% post.day %], [% post.year %]</small></a></h1></div>

    <data class="dt-published" value="<%= $title  %> <%= $post->hms %>"></data>
    <data class="p-author h-card">
        <data class="p-name" value="<%= $post->plerd->author_name | html %>"></data>
    </data>
    <data class="p-summary" value="<%= $post->description | html %>"></data>
    <data class="u-url u-uid" value="<%= $post->uri =%>"></data>
    <div class="byline"><%= $post->attributes->byline %></div>
    <div class="body e-content"><%= post.body %></div>
</div>
% }

% if (@posts == 1) {

    <div>
        <hr />
        %  if ($post->newer_posts) {
            <p>Next post: <a href="[% post.newer_post.uri %]">[% post.newer_post.title %]</a></p>
        % }
        %  if ($post->older_posts) {
            <p>Previous post: <a href="<%= $post->older_post->uri %>"><%= $post->older_post->title %></a></p>
        % }
    </div>

    % if ( $post->ordered_webmentions && @{$post->ordered_webmentions}  > 0 ) {
    <hr />
    <h3>Responses from around the web...</h3>
        <div class="row">
            <div class="col-xs-6">
                %= include  _likes
            </div>
            <div class="col-xs-6">
                %= include _reposts
            </div>
        </div>
        <div class="row">
            <div class="col-xs-12">
                %= include _responses
            </div>
        </div>
    % }
% }

<style>
/* img.media-object { max-width: 64px } */
</style>



@@ _facepile.html.ep
    <p>
    % $count = 0;
    % foreach  my $webmention (@{$post->ordered_webmentions}) {
        % if ($webmention->type eq $type){
            <a href="<%= $webmention->author->url %>"><img class="facepile" src="<%= $webmention->author->photo %>" alt="<%= $webmention->author->name %> avatar" style="width:32px"></a>
            % $count++;
        % }
        % unless ($count) {
          (None yet!)
        %}
    </p>
    % }

@@ _reposts.html.ep
<h4>Reposts</h4>
%= include _facepile type="repost"

@@ _responses.html.ep
    <h4>Replies and mentions</h4>
    % my $count = 0;
    % foreach my $webmention ( @{ $post->ordered_webmentions } ) {
        % unless ($webmention->type eq 'like' || $webmention->type == 'repost') {
        % $count++
        <div class="media">
            <div class="media-left">
                % if ( $webmention->type eq 'mention' ) {
                <a rel="nofollow" href="<%= $webmention->original_source %>">
                <img class="media-object" src="http://fogknife.com/images/comment.png" alt="A generic word balloon" style="max-width:32px; max-height:32px;">
                </a>
                % } else {
                <a rel="nofollow" href="<%= $webmention->author->original_source %>">
                <img class="media-object" src="<%=  $webmention->author->photo %>" alt="<%=  $webmention->author->name %> avatar" style="max-width:32px; max-height:32px;">
                </a>
                % }
            </div>
            <div class="media-body">
                % if ($webmention->type eq 'mention') {
                <h4 class="media-heading">Mentioned on <a href="[% webmention.original_source %]">[% webmention.original_source.host %]</a>...</h4>
                % } else {
                <h4 class="media-heading"><a href="[% webmention.author.url %]">[% webmention.author.name %]</a></h4>
                % }
                    <%= $webmention->content %> <a rel="nofollow" href="<%= $webmention->original_source %>"><span class="glyphicon glyphicon-share" style="text-decoration:none; color:black;"></a>
            </div>
        </div>
        % }
    % }
    % unless ($count) {
        (None yet!)
    %}


