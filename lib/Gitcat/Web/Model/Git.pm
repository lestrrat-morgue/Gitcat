package Gitcat::Web::Model::Git;
use Moose;
use MooseX::Types::Path::Class;
use Gitcat::Repository;
use namespace::clean -except => qw(meta);

extends 'Catalyst::Model';

has repo_root => (
    is => 'ro',
    isa => 'Path::Class::Dir',
    coerce => 1,
    predicate => 'has_repo_root',
);

has repos => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_repos {
    my $self = shift;

    my @repos;
    if ($self->has_repo_root) {
        # XXX P::C::Dir has a recurse, but no prune option. grrr.
        # we'll just do a shallow check for now
        my $repo_root = $self->repo_root->resolve->absolute;
        while (my $next = $repo_root->next) {
            next unless $next->is_dir;
            $next = $next->resolve->absolute;
            next if $next eq $repo_root;
            next if $next->subsumes(Path::Class::Dir->new($repo_root->dir_list));

            my $name = $next->relative( $next->parent );
            push @repos, {
                name => $name,
                directory => $next,
                repository => Gitcat::Repository->new(
                    -d $next->subdir('.git') ? 
                        (gitdir => $next->subdir('.git')) :
                        (gitdir => $next)
                ),
            };
        }
    }
    return { map { ($_->{name} => $_) } @repos }
}

sub load {
    my ($self, $id) = @_;

    if ( ! exists $self->repos->{ $id }) {
        return ;
    }

    my $repo = $self->repos->{$id}->{repository};
    if (! $repo) {
        my $config = $self->repos->{$id};
        $repo = Gitcat::Repository->new(
            directory => $config->{directory}
        );

        $config->{repository} = $repo;
    }
    return $repo;
}

__PACKAGE__->meta->make_immutable();

1;
