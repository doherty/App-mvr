
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "move",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "App-mvr",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "App::mvr",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "POSIX" => 0,
    "Path::Tiny" => 0,
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "perl" => "v5.14.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/mvr"
  ],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "Test::Script::Run" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
