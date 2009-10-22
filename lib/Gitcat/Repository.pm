package Gitcat::Repository;
use Moose;
use MooseX::Types::Path::Class;
use DateTime;
use Gitcat::Tree;
use namespace::clean -except => qw(meta);

extends 'Git::PurePerl';

has git => (
    is => 'ro',
    isa => 'Path::Class::File',
    lazy_build => 1,
);

has tree_class => (
    is => 'ro',
    isa => 'ClassName',
    default => 'Gitcat::Tree',
);

sub _build_git {
    my @paths = split(/:/, $ENV{GITCAT_GIT_PATH} || "/opt/local/bin:/usr/local/bin:/usr/bin:/bin");
    foreach my $path (@paths) {
        my $x = Path::Class::File->new( $path, 'git' );
        if( -x $x ) {
            return $x;
        }
    }
    confess "Could not find git executable";
}


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

sub get_history {
    my ($self, $ref, @options) = @_;

    my $fh = $self->execfh("rev-list", "-z", "--header", $ref, @options);

    my @history;

    local $/ = "\0";
    while (<$fh>) {
        /^(^[0-9a-zA-Z]+)/;
        push @history, $self->get_object($1);
    }
    return @history;
}

sub get_last_activity {
    my $self = shift;

    my $fh = $self->execfh("for-each-ref", 
         '--format=%(committer)',
         '--sort=-committerdate',
         '--count=1',
         'refs/heads'
    );

    my $most_recent = <$fh>;
    close($fh);

    if ($most_recent && $most_recent =~ / (\d+) ([-+][01]\d\d\d)$/) {
        return DateTime->from_epoch(epoch => $1, time_zone => $2);
    }
    return;
}

sub get_owner {
    my $self = shift;

    my $stat = $self->gitdir->stat;
    my ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwuid($stat->uid);
    if (!defined $gcos) {
        return;
    }
    my $owner = $gcos;
    $owner =~ s/[,;].*$//;
    return $owner;
}

sub get_diff {
    my ($self, $sha1, $parent_sha1) = @_;

    my $fh = $self->execfh("diff", $parent_sha1, $sha1);
    return do { local $/; <$fh> }
}

sub get_diff_summary {
    my ($self, $sha1, $parent_sha1) = @_;

    my $fh = $self->execfh("diff", "--stat", "--summary", $parent_sha1, $sha1);
    return do { local $/; <$fh> }
}

sub cmd {
    my ($self, @args) = @_;
    return ( $self->git, '--git-dir='. $self->gitdir(), @args );
}

sub execfh {
    my ($self, @args) = @_;
    my @cmd = $self->cmd(@args);
    open my $fh, "-|", @cmd or confess "Failed to execute @cmd: $!";
    binmode($fh, ':utf8');
    return $fh;
}



__PACKAGE__->meta->make_immutable();

1;
