package Gitcat::Commit::Actor;
use Moose;
use DateTime;
use namespace::clean -except => qw(meta);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has email => (
    is => 'ro',
    isa => 'Str'
);

has committed_on => (
    is => 'ro',
    isa => 'DateTime',
);

package Gitcat::Commit;
use Moose;
use namespace::clean -except => qw(meta);

has author => (
    is => 'ro',
    isa => 'Gitcat::Commit::Actor',
);

has comment => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has short_comment => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has committer => (
    is => 'ro',
    isa => 'Gitcat::Commit::Actor',
    handles => [ 'committed_on' ]
);

has parent => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has parents => (
    is => 'ro',
    isa => 'ArrayRef',
);

has sha1 => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has tree => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub _build_parent {
    my $self = shift;
    return $self->parents->[0];
}

sub new_from_text {
    my ($class, $text) = @_;

    my @lines = split /\n/, $text;

    # first line is a bit different
    my ($sha1, @parents) = split /\s+/, shift @lines;

    my %args = (
        sha1 => $sha1,
        parents => \@parents
    );

    my $sha1_re = qr/[0-9a-fA-F]{40}/;
    while (my $line = shift @lines) {
        last unless $line =~ /\S+/;
        if ( $line =~ /^tree ($sha1_re)$/ ) {
            $args{tree} = $1;
        } elsif ($line =~ /^parent ($sha1_re)$/) {
            push @parents, $1;
        } elsif ($line =~ /^author (.+) ([0-9]+) .+$/) {
            my %actor_args = (
                name => $1,
                committed_on => DateTime->from_epoch(epoch => $2, time_zone => 'local')
            );
            if ($actor_args{name} =~ /^([^<]+) <([^>]*)>/) {
                $actor_args{email} = $2;
                $actor_args{name} = $1;
            }
            $args{author} = Gitcat::Commit::Actor->new(%actor_args);
        } elsif ($line =~ /^committer (.+) ([0-9]+) .+$/) {
            my %actor_args = (
                name => $1,
                committed_on => DateTime->from_epoch(epoch => $2, time_zone => 'local')
            );
            if ($actor_args{name} =~ /^([^<]+) <([^>]*)>/) {
                $actor_args{email} = $2;
                $actor_args{name} = $1;
            }
            $args{committer} = Gitcat::Commit::Actor->new(%actor_args);
        }
    }

    $args{comment} = join("\n", map  { s/^    //; $_ } @lines);
    $args{short_comment} = substr($args{comment}, 0, 50);

    return $class->new(%args);
}

__PACKAGE__->meta->make_immutable();

1;
