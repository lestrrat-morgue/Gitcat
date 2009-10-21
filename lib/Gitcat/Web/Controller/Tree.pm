package Gitcat::Web::Controller::Tree;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

sub view
    :Chained('/branch/load')
    :PathPart('tree')
    :Args
{
    my ($self, $c, @comps) = @_;

    my $repo   = $c->stash->{repo};
    my $object = @comps > 0 ? 
        $repo->get_object_from_path($c->stash->{branch_id}, @comps) :
        $repo->get_object($c->stash->{branch}->sha1)->tree
    ;

    # switch template depending on the object type
    $c->stash(
        object => $object,
        template => sprintf('tree/%s.tt', $object->kind),
    );
}

__PACKAGE__->meta->make_immutable();

1;
