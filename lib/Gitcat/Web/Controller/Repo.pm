package Gitcat::Web::Controller::Repo;
use Moose;
use namespace::clean -except => qw(meta);

BEGIN { extends 'Catalyst::Controller' }

sub load
    :Chained
    :PathPart('repo')
    :CaptureArgs(1)
{
    my ($self, $c, $id) = @_;

    my $git = $c->model('Git')->load($id);

    $c->stash(
        repo_id => $id,
        repo => $git,
    );
}

sub view
    :Chained('/repo/load')
    :PathPart('')
    :Args(0)
{
    my ($self, $c) = @_;
    my $repo_id = $c->stash->{repo_id};
    $c->res->redirect( "/repo/$repo_id/branch/master/summary" );
}

__PACKAGE__->meta->make_immutable();

1;
