package Gitcat::Object;
use Moose;
use namespace::clean -except => qw(meta);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has kind => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has mode => (
    is => 'ro',
    required => 1
);

has sha1 => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has content => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

__PACKAGE__->meta->make_immutable;

1;
