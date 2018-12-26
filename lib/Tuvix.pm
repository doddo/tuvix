package Tuvix;
use Mojo::Base 'Mojolicious';
use Tuvix::Model::Posts;
use Tuvix::Model::BlogInfo;
use Mojo::Unicode::UTF8;
use Tuvix::Schema;
use Mojo::Headers;

sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->secrets($self->config('secrets'));

    $self->helper(plerd => sub {Tuvix::Model::BlogInfo->new($self->config('plerd'))});
    $self->helper(bloginfo => sub {
        my $self = shift;
        my $key = shift;
        $self->plerd->$key()
    });
    $self->helper(posts => sub {
        Tuvix::Model::Posts->new(db => $self->config('db'), db_opts => $self->config('db_opts'))
    });
    $self->helper(recent_posts => sub {shift->posts->get_recent_posts()});;

    push @{$self->static->paths}, $self->plerd->publication_path;

    # Controller
    my $r = $self->routes;

    $r->get('/' => sub {
        my $c = shift;

        my $webmention_url = (${$c->app->config}{listening_port_in_uris} // 0)
            ? Mojo::URL->new('/webmention')->base($c->plerd->webmention_uri->base->port($c->tx->local_port))
            : $c->plerd->webmention_uri();

        $c->res
            ->headers
            ->append(Link => sprintf '"<%s>; rel=\"webmention\"', $webmention_url->to_abs);
        $c->redirect_to('posts')
    });
    $r->get('/posts')->to('posts#get_posts');
    $r->get('/posts/archive')->to('posts#get_archive');
    #$r->post('/posts/search')->to('posts#search');
    $r->get('/posts/#postpath')->to('posts#get_posts_from_path');
    #$r->post('/webmention')->to('webmentions#process_webmention');

    $r->websocket('/more_posts')->to('posts#load_next');

}

1;
