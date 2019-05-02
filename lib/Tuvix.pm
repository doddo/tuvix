package Tuvix;
use Mojo::Base 'Mojolicious';
use Tuvix::Model::Posts;
use Tuvix::Model::SiteInfo;
use Tuvix::Task::Watcher;
use Tuvix::Schema::ResultSet::Webmention;
use Mojo::Unicode::UTF8;
use Mojo::URL;

use Tuvix::Schema;
use Mojo::Headers;
use Minion::Backend::SQLite;
use Mojo::SQLite;

use Mojo::File 'path';
use Mojo::Home;


# Every CPAN module needs a version
our $VERSION = '1.0';


sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->secrets($self->config('secrets'));

    # Switch to installable home directory
    $self->home(Mojo::Home->new(path(__FILE__)->sibling('Tuvix')));

    # Switch to installable "public" directory
    $self->static->paths->[0] = $self->home->child('public');

    # Switch to installable "templates" directory
    # Todo here can be a different when theme support is added.
    $self->renderer->paths->[0] = $self->home->child('templates');

    # Add App specific command namespace.
    push @{$self->commands->namespaces}, 'Tuvix::Command';


    $self->helper(site_info => sub {Tuvix::Model::SiteInfo->new($self->config)});
    $self->helper(site_info_get => sub {
        my $self = shift;
        my $key = shift;
        $self->site_info->$key()
    });
    $self->helper(posts => sub {
        Tuvix::Model::Posts->new(db => $self->config('db'), db_opts => $self->config('db_opts'))
    });

    $self->helper(schema => sub {
        state $schema = Tuvix::Schema->connect(@{$self->config('db')}, $self->config('db_opts'))
    });

    $self->helper(recent_posts => sub {shift->posts->get_recent_posts()});

    $self->helper(base_url => sub {shift->site_info->base_uri});
    $self->helper(webmention_url => sub {Mojo::URL->new('/webmention')->base(shift->site_info->base_uri)});

    # For the websocket URI
    $self->helper(websocket_url => sub {
        my $self = shift;
        return Mojo::URL
            ->new('/more_posts')
            ->host_port($self->site_info->base_uri->host_port)
            ->scheme($self->site_info->base_uri->scheme eq 'https' ? 'wss' : 'ws')
    });

    # For the minions
    # Maybe they ought to have their own db # TODO
    $self->helper(sqlite => sub {
        state $sqlite = Mojo::SQLite->new(substr(@{$self->config('db')}[0], 4))});


    # Expose publication path to the web.
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
    $r->get('/posts/#postpath')->to('posts#get_posts_from_path');

    $r->post('/posts/search')->to('posts#search');
    $r->post('/webmention')->to('webmentions#process_webmention');

    $r->websocket('/more_posts')->to('posts#load_next');

    #
    # Share the database connection cache
    $self->plugin('Mojolicious::Plugin::Minion', { SQLite => $self->sqlite });

    # The Tasks
    $self->plugin('Tuvix::Task::Watcher');
    $self->plugin('Tuvix::Task::Webmention');

}

1;
