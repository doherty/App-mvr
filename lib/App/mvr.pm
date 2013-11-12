package App::mvr;
use v5.14.0;
use strict;
use warnings;
# ABSTRACT: like mv, but clever
# VERSION

use Exporter qw(import);
our @EXPORT = qw(mvr);

use Path::Tiny 0.034;
use Try::Tiny;
use Carp;

our $VERBOSE = 0;

=head1 FUNCTIONS

=head2 mvr

Rename SOURCE to DEST, or move SOURCE(S) to DIRECTORY.

    mvr( source => 'file.txt', dest => '~/Documents' );         # move file.txt into ~/Documents
    mvr( source => 'file.txt', dest => '~/Documents/notes.txt );# move to specified name
    mvr( source => [map "$_.txt", qw/a b c/], dest => '~' );    # move multiple files into ~/

Parameters are key-value pairs:

=over 4

=item source

An arrayref of source files, or a single scalar if you have only one file.

=item dest

The target pathname. If this is a directory, file(s) will be moved into it - or
an exception will be raised if the directory doesn't exist.

=item deduplicate

Check if files are the same whenever there is a name conflict. If they are the
same, then just remove the source file instead of adding another copy to the
destination.

=back

This function is not exported by default.

=cut

my $duplicates = sub {
    my $A = shift;
    my $B = shift;
    return if $A->stat->size != $B->stat->size; # avoid reading file off disk

    # Pull out the big guns
    return $A->digest eq $B->digest;
};

sub mvr {
    my %args = @_;
    $args{dest}   //= delete $args{destination};
    $args{source} = [delete $args{source}] unless ref $args{source} eq 'ARRAY';

    my $dest = path( $args{dest} );
    my $dest_is_dir = $dest->exists && $dest->is_dir;
    croak sprintf("target `%s' is not a directory\n", $dest)
        if @{ $args{source} } > 1 and !$dest_is_dir;

    STDOUT->autoflush(1) if $VERBOSE;
    foreach my $from ( map { path($_) } @{ $args{source} } ) {
        print "\r${from}\e[K" if $VERBOSE == 1;

        unless ($from->exists) {
            carp sprintf("Cannot stat `%s': No such file or directory\n", $from);
            next;
        }
        my $to = path( $dest, ($dest_is_dir ? $from->basename : ()) );
        croak sprintf("`%s' and `%s' are the same file\n", $to, $from)
            if $from->absolute eq $to->absolute;

        if ($to->exists) {
            if ($args{deduplicate}) {
                print STDERR "File already exists; checking for duplication..."
                    if $VERBOSE > 1;
                if ($duplicates->($from, $to)) {
                    printf STDERR
                        " `%s' and `%s' are duplicates; removing the source file.\n",
                        $from->basename, $to->basename
                        if $VERBOSE > 1;
                    $from->remove;
                    $to->touch;
                    next;
                }
                else {
                    printf STDERR
                        " `%s' and `%s' are not duplicates.\n",
                        $from->basename, $to->basename
                        if $VERBOSE > 1;
                }
            }

            my ($prefix, $suffix) = $to->basename =~ m{^(.*)\.(\w+)$};
            $to = Path::Tiny->tempfile(
                UNLINK => 0,
                TEMPLATE => ($prefix // $to->basename) . '-XXXXXX',
                DIR => $dest_is_dir ? $dest : $dest->dirname,
                ( $suffix ? (SUFFIX => ".$suffix") : () ),
            );
            printf STDERR "File already exists; renaming `%s' to `%s'\n",
                $from->basename, $to->basename
                if $VERBOSE > 1;
        }

        try {
            $from->move($to);
        }
        catch {
            use POSIX qw(:errno_h);
            if ($_->{err} == EXDEV) { # Invalid cross-device link
                printf STDERR "File can't be renamed across filesystems; copying `%s' to `%s' instead...",
                    $from->basename, $to->basename
                    if $VERBOSE > 1;
                $from->copy($to);
                $to->touch( $from->stat->mtime );
                print STDERR " done. Removing original file.\n" if $VERBOSE > 1;
                $from->remove;
            }
            else {
                die $_;
            }
        };
    }
}

1;
