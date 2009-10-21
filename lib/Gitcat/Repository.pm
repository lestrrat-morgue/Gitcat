package Gitcat::Repository;
use Moose;
use Gitcat::Tree;
use namespace::clean -except => qw(meta);

extends 'Git::PurePerl';

has tree_class => (
    is => 'ro',
    isa => 'ClassName',
    default => 'Gitcat::Tree',
);

override create_object => sub {
    my ( $self, $sha1, $kind, $size, $content ) = @_;
    if ($kind eq 'tree') {
        return $self->tree_class->new(
            sha1    => $sha1,
            kind    => $kind,
            size    => $size,
            content => $content,
            git     => $self,
        );
    }
    return super();
};

sub get_object_from_path {
    my ($self, $parent_sha1, @args) = @_;

    my $parent = $self->get_object($parent_sha1);
    if ($parent->kind eq 'commit') {
        $parent = $parent->tree;
    }

    my @comps = @args;

    while ($parent->kind eq 'tree' && (my $next = shift @comps)) {
        my $found = 0;

        foreach my $e ($parent->directory_entries) {
            if ($e->filename eq $next) {
                $found = 1;
                if (! @comps) {
                    return $e->object;
                }
                $parent = $e->object;
                last; 
            }
        }

        if (! $found && @comps ) {
            confess "Could not find " . join('/', @args);
        }
    }
}

__PACKAGE__->meta->make_immutable();

1;
