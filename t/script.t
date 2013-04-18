use strict;
use warnings;
use Test::More tests => 4;
use Test::Script::Run;
use Path::Tiny;

END { path('corpus')->remove_tree }

subtest plain => sub {
    plan tests => 8;

    path('corpus')->remove_tree;
    path('corpus', "$_.txt")->touchpath for qw( one two three d/three );

    run_ok( 'mvr', ["corpus/$_.txt", "corpus/d" ], 'renames OK' )
        for (qw/ one two three /);

    ok path('corpus', 'd', "$_.txt")->exists, "corpus/d/$_.txt exists"
        for (qw/ one two three /);

    my @files = grep { defined and $_->basename !~ qr/^(?:one|two|three)\.txt$/ } path('corpus/d')->children;
    is scalar @files => 1;
    like $files[0] => qr{three-.{6}\.txt$} or diag $files[0];
    note "found $files[0]";
    note `ls -lR corpus`;
};

subtest 'file ext' => sub {
    plan tests => 8;

    path('corpus')->remove_tree;
    path('corpus', $_)->touchpath for qw( one two three d/three );

    run_ok( 'mvr', ["corpus/$_", "corpus/d" ], 'renames OK' )
        for (qw/ one two three /);

    ok path('corpus', 'd', $_)->exists, "corpus/d/$_ exists"
        for (qw/ one two three /);

    my @files = grep { defined and $_->basename !~ qr/^(?:one|two|three)$/ } path('corpus/d')->children;
    is scalar @files => 1;
    like $files[0] => qr{three-.{6}};
    note "found $files[0]";
    note `ls -lR corpus`;
};

subtest verbose => sub {
    plan tests => 2;

    path('corpus')->remove_tree;
    path('corpus', $_)->touchpath for qw( verbose d/verbose );

    run_script( 'mvr', [qw( corpus/verbose corpus/d/verbose )], \my $out, \my $err );
    is $out => '';
    like $err => qr{\QFile already exists};
};

subtest quiet => sub {
    plan tests => 2;

    path('corpus')->remove_tree;
    path('corpus', $_)->touchpath for qw( quiet d/quiet );

    run_script( 'mvr', [qw( --quiet corpus/quiet corpus/d/ )], \my $out, \my $err );
    is $out => '';
    is $err => '';
};
