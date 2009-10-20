package Gitcat::Web::Controller::Root;
use Moose;
use namespace::clean -except => qw(meta);

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = '';

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        repos => $c->model('Git')->repos,
    );
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

1;
