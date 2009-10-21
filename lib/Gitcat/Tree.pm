package Gitcat::Tree;
use Moose;
use Gitcat::DirectoryEntry;
use namespace::clean -except => qw(meta);

extends 'Git::PurePerl::Object::Tree';

override _build_directory_entries => sub {
    my $self = shift;
    my $ret = super();
    my $meta = Gitcat::DirectoryEntry->meta;
    return [ map {
        $meta->rebless_instance( $_ )
    } @$ret ];
};

__PACKAGE__->meta->make_immutable();

1;
