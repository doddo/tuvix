package Tuvix;
use Mojo::Base 'Mojolicious';
use Tuvix::Model::Posts;
use Tuvix::Model::SiteInfo;
use Mojo::Unicode::UTF8;
use Mojo::URL;
use Tuvix::Schema;
use Mojo::Headers;

sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->secrets($self->config('secrets'));

    $self->helper(site_info => sub {Tuvix::Model::SiteInfo->new($self->config('plerd'))});
    $self->helper(site_info_get => sub {
        my $self = shift;
        my $key = shift;
        $self->site_info->$key()
    });
    $self->helper(posts => sub {
        Tuvix::Model::Posts->new(db => $self->config('db'), db_opts => $self->config('db_opts'))
    });
    $self->helper(recent_posts => sub {shift->posts->get_recent_posts()});

    $self->helper(base_url => sub {shift->site_info->base_uri});
    $self->helper(webmention_url => sub {Mojo::URL->new('/webmention')->base(shift->site_info->base_uri)});

    push @{$self->static->paths}, $self->site_info->publication_path;

    # Controller
    my $r = $self->routes;

    $r->get('/' => sub {
        my $c = shift;

        my $webmention_url = $c->webmention_url->to_abs;

        $c->res
            ->headers
            ->append(Link => sprintf '<%s>; rel="webmention"', $webmention_url->to_abs);
        $c->redirect_to('posts')
    });
    $r->get('/posts')->to('posts#get_posts');
    $r->get('/posts/archive')->to('posts#get_archive');
    #$r->post('/posts/search')->to('posts#search');
    $r->get('/posts/#postpath')->to('posts#get_posts_from_path');
    $r->post('/webmention')->to('webmentions#process_webmention');

    $r->websocket('/more_posts')->to('posts#load_next');

}

1;
