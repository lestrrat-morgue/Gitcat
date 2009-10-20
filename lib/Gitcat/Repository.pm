package Gitcat::Repository;
use Moose;
use MooseX::Types::Path::Class;
use DateTime;
use Gitcat::Commit;
use namespace::clean -except => qw(meta);

has config => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

has description => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has directory => (
    is => 'ro',
    isa => 'Path::Class::Dir',
    coerce => 1,
    required => 1,
);

has git => (
    is => 'ro',
    isa => 'Path::Class::File',
    coerce => 1,
    lazy_build => 1,
);

has gitdir => (
    init_arg => undef,
    is => 'ro',
    isa => 'Path::Class::Dir',
    coerce => 1,
    lazy_build => 1,
);

has is_bare => (
    is => 'ro',
    isa => 'Bool',
    lazy_build => 1,
);

has last_change => (
    is => 'ro',
    isa => 'DateTime',
    lazy_build => 1,
);

has owner => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_config {
    my $self = shift;
    local $/ = "\0";

    my @cmd = $self->git_cmd('config', '-z', '-l');
    open my $fh, "-|", @cmd or confess "Could not execut @cmd: $!";

    my %config;
    while (my $line = <$fh>) {
        chomp $line;
        my ($key, $value) = split(/\n/, $line, 2);

        $config{ $key } = $value;
    }
    return \%config;
}

sub _build_git {
    return "/opt/local/bin/git";
}

sub _build_is_bare {
    my $self = shift;

    if (-d $self->directory->subdir('.git')) {
        return ();
    } else {
        return 1;
    }
}

sub _build_description {
    my $self = shift;

    my $file = $self->gitdir->file('description');
    return $file->slurp();
}

sub _build_gitdir {
    my $self = shift;

    return $self->is_bare ?
        Path::Class::Dir->new( $self->directory ) :
        $self->directory->subdir('.git')
    ;
}

sub _build_last_change {
    my $self = shift;

    my @cmd = $self->git_cmd(
        'for-each-ref',
        '--format=%(committer)',
        '--sort=-committerdate',
        '--count=1',
        'refs/heads'
    );
    open my $fh, "-|", @cmd or confess "Cannot execute @cmd: $!";

    my $most_recent = <$fh>;
    close $fh or return;
    if (defined $most_recent &&
        $most_recent =~ / (\d+) [-+][01]\d\d\d$/) {
        return DateTime->from_epoch(epoch => $1, time_zone => 'local');
    }
}

sub _build_owner {
    my $self = shift;

    my $owner = $self->config->{owner};

    if (! $owner) {
        my $stat = $self->directory->stat();
        my $gcos = (getpwuid( $stat->uid ))[6];

        $owner = $gcos;
        $owner =~ s/[,;].*$//;
    }

    if (! $owner) {
        $owner = 'Unknown';
    }
    return $owner;
}

sub git_cmd {
    my ($self, @args) = @_;
    return ( $self->git, '--git-dir='. $self->gitdir(), @args );
}
    

sub commits {
    my ($self, $sha1) = @_;

    $sha1 ||= 'refs/heads/master';

    my @commits;
    my $maxcount = 10;
    my @args;
    my @cmd = $self->git_cmd("rev-list", "--header", $sha1, @args, "--max-count=$maxcount");
    open my $fh, "-|", @cmd or confess "Failed to execute @cmd: $!";

    binmode($fh, ':utf8');
    local $/ = "\0";
    while (my $line = <$fh>) {
        chomp $line;
        push @commits, Gitcat::Commit->new_from_text( $line );
    }

    return \@commits;
}

__PACKAGE__->meta->make_immutable();

1;
