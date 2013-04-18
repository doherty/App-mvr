use strict;
use warnings;
use Test::More tests => 2;
use Path::Tiny;
use App::mvr qw( mvr );

END { path('corpus')->remove_tree }

subtest main => sub {
    use Test::Fatal qw( lives_ok );
    plan tests => 6;

    path('corpus')->remove_tree;
    path('corpus', "$_.jpg.tar.gz.txt")->touchpath for qw( one two three d/three );

    lives_ok {
        mvr( source => [map { "corpus/$_.jpg.tar.gz.txt" } qw/ one two three /], dest => 'corpus/d' );
    } "mvr call didn't die";

    ok path('corpus', 'd', "$_.jpg.tar.gz.txt")->exists, "corpus/d/$_.jpg.tar.gz.txt exists"
        for (qw/ one two three /);

    my @files = grep { defined and $_->basename !~ qr/^(?:one|two|three)\Q.jpg.tar.gz.txt\E$/ } path('corpus/d')->children;
    is scalar @files => 1;
    like $files[0] => qr{three\Q.jpg.tar.gz\E-.{6}\.txt$};
    note "found $files[0]";
    note `ls -lR corpus`;
};

subtest verbosity => sub {
    use Capture::Tiny qw(capture);
    plan tests => 4;

    path('corpus')->remove_tree;
    path('corpus', $_)->touchpath for qw( verbose d/verbose );
    {
        my ($out, $err) = capture {
            local $App::mvr::VERBOSE = 1;
            mvr( source => 'corpus/verbose', dest => 'corpus/d/verbose' );
        };
        is $out => '';
        like $err => qr{\QFile already exists};
    }


    path('corpus')->remove_tree;
    path('corpus', $_)->touchpath for qw( verbose d/verbose );
    {
        my ($out, $err) = capture {
            local $App::mvr::VERBOSE;
            mvr( source => 'corpus/verbose', dest => 'corpus/d/verbose' );
        };
        is $out => '';
        is $err => '';
    }
};
