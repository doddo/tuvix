package Tuvix;
use Mojo::Base 'Mojolicious';
use Tuvix::Model::Posts;
use Tuvix::Model::BlogInfo;
use Mojo::Unicode::UTF8;
use Tuvix::Schema;

#use Tuvix::Model::Posts;
#se Blog::Model::Posts;#use Mojo::Pg;

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
    });;
    $self->helper(recent_posts => sub { shift->posts->get_recent_posts() });;


    push @{$self->static->paths}, $self->plerd->publication_path;

    # Controller
    my $r = $self->routes;
    $r->get('/' => sub {shift->redirect_to('posts')});
    $r->get('/posts')->to('posts#get_posts');
    $r->get('/posts/#postpath')->to('posts#get_posts_from_path');
    $r->post('/webmention')->to('webmentions#process_webmention');

    $r->websocket('/more_posts')->to('posts#load_next');
}

1;
