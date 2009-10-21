package Gitcat::DirectoryEntry;
use Moose;
use Fcntl qw(:mode);
use namespace::clean -except => qw(meta);

extends 'Git::PurePerl::DirectoryEntry';

has is_submodule => (
    is => 'ro',
    isa => 'Bool',
    lazy_build => 1,
);

use constant {
    S_IFINVALID => 0030000,
    S_IFGITLINK => 0160000,
};

sub _build_is_submodule {
    my $self = shift;
    return S_ISGITLINK(oct $self->mode);
}

# submodule/subproject, a commit object reference
sub S_ISGITLINK {
    my $mode = shift;
    return (($mode & S_IFMT) == S_IFGITLINK)
}

# convert file mode in octal to symbolic file mode string
sub mode_str {
    my $self = shift;
    my $mode = oct $self->mode;

    if (S_ISGITLINK($mode)) {
        return 'm---------';
    } elsif (S_ISDIR($mode & S_IFMT)) {
        return 'drwxr-xr-x';
    } elsif (S_ISLNK($mode)) {
        return 'lrwxrwxrwx';
    } elsif (S_ISREG($mode)) {
        # git cares only about the executable bit
        if ($mode & S_IXUSR) {
            return '-rwxr-xr-x';
        } else {
            return '-rw-r--r--';
        };
    } else {
        return '----------';
    }
}



# convert file mode in octal to file type string
sub file_type {
    my $self = shift;
    my $mode = $self->mode;

    if ($mode !~ m/^[0-7]+$/) {
        return $mode;
    } else {
        $mode = oct $mode;
    }

    if (S_ISGITLINK($mode)) {
        return "submodule";
    } elsif (S_ISDIR($mode & S_IFMT)) {
        return "directory";
    } elsif (S_ISLNK($mode)) {
        return "symlink";
    } elsif (S_ISREG($mode)) {
        return "file";
    } else {
        return "unknown";
    }
}

# convert file mode in octal to file type description string
sub file_type_long {
    my $self = shift;
    my $mode = $self->mode;

    if ($mode !~ m/^[0-7]+$/) {
        return $mode;
    } else {
        $mode = oct $mode;
    }

    if (S_ISGITLINK($mode)) {
        return "submodule";
    } elsif (S_ISDIR($mode & S_IFMT)) {
        return "directory";
    } elsif (S_ISLNK($mode)) {
        return "symlink";
    } elsif (S_ISREG($mode)) {
        if ($mode & S_IXUSR) {
            return "executable";
        } else {
            return "file";
        };
    } else {
        return "unknown";
    }
}

__PACKAGE__->meta->make_immutable();

1;
