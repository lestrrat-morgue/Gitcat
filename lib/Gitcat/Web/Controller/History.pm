
package Gitcat::Web::Controller::History;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

sub view
    :Chained('/branch/load')
    :PathPart('history')
    :Args
{
    my ($self, $c, @comps) = @_;

    my $repo   = $c->stash->{repo};
    my $branch = $c->stash->{branch};
    my $object = @comps > 0 ? 
        $repo->get_object_from_path($branch->sha1, @comps) :
        $repo->get_object($branch->sha1)->tree
    ;
    my @history = $repo->get_history( $branch->sha1, Path::Class::File->new(@comps) );

    # switch template depending on the object type
    $c->stash(
        object => $object,
        tree_comp => \@comps,
        history   => \@history,
#        template => sprintf('history/%s.tt', $object->kind),
    );
}

__PACKAGE__->meta->make_immutable();

1;
