package Gitcat::Web::Controller::Tree;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

sub view
    :Chained('/branch/load')
    :PathPart('tree')
    :Args
{
    my ($self, $c, @comps) = @_;
    my $object = $c->stash->{repo}->get_object_from_path($c->stash->{branch_id}, @comps);

    # switch template depending on the object type
    $c->stash(
        object => $object,
        template => sprintf('tree/%s.tt', $object->kind),
    );
}

__PACKAGE__->meta->make_immutable();

1;

__END__

    if (! @comps) {
        # We're at root. the target object is the branch
        $args->{path_comps} = [];
        $args->{object_map} = {},
        $args->{object}     = $branch->tree;
        $args->{template} = 'tree/view.tt';
    } else {
        my $parent = $branch->tree;
        my @left = @comps;
        my %comps;
        while (my $next = shift @left) {
            my $found = 0;
            foreach my $e ($parent->directory_entries) {
                if ($e->filename eq $next) {
                    $found = $e;
                    last;
                }
            }
            if (! $found) {
                die "404";
            }

            $parent = $found->object;
            $comps{ $next } = $parent;

            if ($parent->kind ne 'tree' && scalar @left > 0) {
                die "404";
            }
        }

        my $last = $comps{ $comps[-1] };
        $args->{path_comps} = \@comps;
        $args->{object_map} = \%comps;
        $args->{object}     = $last;

        $args->{template} = ($last->kind eq 'tree') ? 'tree/view.tt' : 'blob/view.tt';
    }

    $c->run_template($args->{template}, $args);
}

__PACKAGE__->meta->make_immutable();

1;
