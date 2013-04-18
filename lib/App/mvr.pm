package App::mvr;
use v5.14.0;
use strict;
use warnings;
# ABSTRACT: move
# VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(mvr);

use Path::Tiny;
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
    require Digest::MD5;
    return
        Digest::MD5->new->addfile( $A->filehandle('<', ':raw') )->digest
        eq
        Digest::MD5->new->addfile( $B->filehandle('<', ':raw') )->digest
    ;
};

sub mvr {
    my %args = @_;
    $args{dest}   //= delete $args{destination};
    $args{source} = [delete $args{source}] unless ref $args{source} eq 'ARRAY';

    my $dest = path( $args{dest} );
    my $dest_is_dir = $dest->exists && $dest->is_dir;
    croak "target `$dest' is not a directory\n"
        if @{ $args{source} } > 1 and !$dest_is_dir;

    foreach my $from ( map { path($_) } @{ $args{source} } ) {
        unless ($from->exists) {
            carp "cannot stat `$from': No such file or directory\n";
            next;
        }
        my $to = path( $dest, ($dest_is_dir ? $from->basename : ()) );
        croak "`$to' and `$from' are the same file\n" if $from->absolute eq $to->absolute;

        if ($to->exists) {
            if ($args{deduplicate}) {
                STDERR->autoflush(1);
                print STDERR "File already exists; checking for duplication..." if $VERBOSE;
                if ($duplicates->($from, $to)) {
                    print STDERR " `$from' and `$to' are duplicates; removing the source file.\n" if $VERBOSE;
                    $from->remove;
                    next;
                }
                else {
                    print STDERR " `$from' and `$to' are not duplicates.\n" if $VERBOSE;
                }
            }

            my ($prefix, $suffix) = $to->basename =~ m{^(.*)\.(\w+)$};
            $to = Path::Tiny->tempfile(
                UNLINK => 0,
                TEMPLATE => ($prefix // $to->basename) . '-XXXXXX',
                DIR => $dest_is_dir ? $dest : $dest->dirname,
                ( $suffix ? (SUFFIX => ".$suffix") : () ),
            );
            warn "File already exists; renaming `$from' to `$to'\n" if $VERBOSE;
        }

        try {
            $from->move($to);
        }
        catch {
            die $_ unless $_->isa('autodie::exception');

            use POSIX qw(:errno_h);
            if ($_->errno == EXDEV) { # Invalid cross-device link
                STDERR->autoflush(1);
                print STDERR "File can't be renamed across filesystems; copying `$from' to `$to' instead..."
                    if $VERBOSE;
                $from->copy($to);
                print STDERR " done. Removing original file.\n" if $VERBOSE;
                $from->remove;
            }
            else {
                die $_;
            }
        };
    }
}

1;
