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
    my $branch = $c->stash->{branch};
    my $object = @comps > 0 ? 
        $repo->get_object_from_path($branch->sha1, @comps) :
        $repo->get_object($branch->sha1)->tree
    ;

    # switch template depending on the object type
    $c->stash(
        object => $object,
        tree_comp => \@comps,
        template => sprintf('tree/%s.tt', $object->kind),
    );
}

__PACKAGE__->meta->make_immutable();

1;
