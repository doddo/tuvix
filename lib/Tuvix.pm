package Tuvix;
use Mojo::Base 'Mojolicious';
use Tuvix::Model::Posts;
use Tuvix::Model::SiteInfo;
use Tuvix::Watcher;
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
    my ($app, @args) = @_;
    $app->log->info(sprintf ("started $0 with:[%s]", join(', ', @args)));

    $app->plugin('Config');
    $app->secrets($app->config('secrets'));

    # Switch to installable home directory
    $app->home(Mojo::Home->new(path(__FILE__)->sibling('Tuvix')));

    # Switch to installable "public" directory
    $app->static->paths->[0] = $app->home->child('public');

    # Switch to installable "templates" directory

    $app->renderer->paths->[0] = $app->home->child('templates');

    if ($app->config('templates_path')){
        # custom templates take precedence.
        $app->log->info(sprintf "Adding custom templates_path: '%s'", $app->config('templates_path'));
        unshift @{$app->renderer->paths}, $app->config('templates_path');
    }

    # Add App specific command namespace.
    push @{$app->commands->namespaces}, 'Tuvix::Command';

    $app->helper(site_info => sub {Tuvix::Model::SiteInfo->new($app->config)});
    $app->helper(site_info_get => sub {
        my $self = shift;
        my $key = shift;
        $self->site_info->$key()
    });
    $app->helper(posts => sub {
        Tuvix::Model::Posts->new(db => $app->config('db'), db_opts => $app->config('db_opts'))
    });

    $app->helper(schema => sub {
        state $schema = Tuvix::Schema->connect(@{$app->config('db')}, $app->config('db_opts'))
    });

    $app->helper(recent_posts => sub {shift->posts->get_recent_posts()});

    $app->helper(base_url => sub {shift->site_info->base_uri});
    $app->helper(webmention_url => sub {Mojo::URL->new('/webmention')->base(shift->site_info->base_uri)});

    # For the websocket URI
    $app->helper(websocket_url => sub {
        my $self = shift;
        return Mojo::URL
            ->new('/more_posts')
            ->host_port($self->site_info->base_uri->host_port)
            ->scheme($self->site_info->base_uri->scheme eq 'https' ? 'wss' : 'ws')
    });

    # For the minions
    # Maybe they ought to have their own db # TODO
    $app->helper(sqlite => sub {
        state $sqlite = Mojo::SQLite->new(substr(@{$app->config('db')}[0], 4))});

    # Expose publication path to the web.
    push @{$app->static->paths}, $app->site_info->publication_path;

    # Controller
    my $r = $app->routes;

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

    # Share the database connection cache
    $app->plugin('Mojolicious::Plugin::Minion::Workers', { SQLite => $app->sqlite });

    # The Tasks
    $app->plugin('Tuvix::Task::Webmention');

    $app->hook(before_server_start => sub {
        my ($server, $app) = @_;
        if ($app->config('watch_source_dir') // 0) {
            $app->log->info("starting to watch the source dir.");
            my $watcher = Tuvix::Watcher->new(config => $app->config);
            my $watcher_pid = $watcher->start();
        }
        else {
            $app->log->info("starting without watching source dir.");
        };
    });
}

1;
