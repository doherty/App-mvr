use strict;
use warnings;
use Test::More tests => 4;
use Test::Script::Run;
use Path::Tiny;

my $wd = path( 'corpus', path(__FILE__)->basename );
END { path($wd)->remove_tree }

subtest plain => sub {
    plan tests => 8;

    path($wd)->remove_tree;
    path($wd, "$_.txt")->touchpath for qw( one two three d/three );

    run_ok( 'mvr', [path($wd, "$_.txt"), path($wd, 'd') ], 'renames OK' )
        for (qw/ one two three /);

    ok path($wd, 'd', "$_.txt")->exists, "d/$_.txt exists"
        for (qw/ one two three /);

    my @files = grep {
        defined
        and $_->basename !~ qr/^(?:one|two|three)\.txt$/
    } path($wd, 'd')->children;
    is scalar @files => 1;
    like $files[0] => qr{three-.{6}\.txt$} or diag $files[0];
    note "found $files[0]";
    note `ls -lR corpus`;
};

subtest 'file ext' => sub {
    plan tests => 8;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( one two three d/three );

    run_ok( 'mvr', [path($wd, $_), path($wd, 'd') ], 'renames OK' )
        for (qw/ one two three /);

    ok path($wd, 'd', $_)->exists, "d/$_ exists"
        for (qw/ one two three /);

    my @files = grep {
        defined
        and $_->basename !~ qr/^(?:one|two|three)$/
    } path($wd, 'd')->children;
    is scalar @files => 1;
    like $files[0] => qr{three-.{6}};
    note "found $files[0]";
    note `ls -lR corpus`;
};

subtest verbose => sub {
    plan tests => 2;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( verbose d/verbose );

    run_script( 'mvr',
        [path($wd, 'verbose'), path($wd, 'd', 'verbose') ],
        \my $out, \my $err
    );
    is $out => '';
    like $err => qr{\QFile already exists};
};

subtest quiet => sub {
    plan tests => 2;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( quiet d/quiet );

    run_script( 'mvr',
        ['--quiet', path($wd, 'quiet'), path($wd, 'd')],
        \my $out, \my $err
    );
    is $out => '';
    is $err => '';
};
