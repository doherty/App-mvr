
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "like mv, but clever",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "App-mvr",
  "EXE_FILES" => [
    "bin/mvr"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::mvr",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "POSIX" => 0,
    "Path::Tiny" => 0,
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "Test::Script::Run" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



