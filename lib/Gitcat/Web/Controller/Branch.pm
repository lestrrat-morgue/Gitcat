package Gitcat::Web::Controller::Branch;
use Moose;
use namespace::clean -except => qw(meta);

BEGIN { extends 'Catalyst::Controller' }

sub load
    :Chained('/repo/load')
    :PathPart('branch')
    :CaptureArgs(1)
{
    my ($self, $c, $branch_id) = @_;

    my $repo = $c->stash->{repo};
    $c->stash(
        branch_id => $branch_id,
        branch => $repo->ref("refs/heads/$branch_id"),
    );
}

sub branch_noarg
    :Chained('/repository/load')
    :PathPart('')
    :Args(0)
{
    my ($self, $c) = @_;

    my $repo_id = $c->stash->{repo_id};
    $c->res->redirect("/repo/$repo_id/branch/master");
}

sub commits
    :Chained('/branch/load')
    :PathPart('commits')
    :Args(0)
{
}

sub summary
    :Chained('/branch/load')
    :PathPart('summary')
    :Args(0)
{
}

__PACKAGE__->meta->make_immutable();

1;

