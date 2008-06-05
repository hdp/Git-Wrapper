use strict;
use warnings;
use Test::More 'no_plan';

use File::Temp qw(tempdir);
use IO::File;
use Git::Wrapper;
use File::Spec;
use File::Path qw(mkpath);

my $dir = tempdir(CLEANUP => 1);

my $git = Git::Wrapper->new($dir);

$git->init;

mkpath(File::Spec->catfile($dir, 'foo'));

IO::File->new(">" . File::Spec->catfile($dir, qw(foo bar)))->print("hello\n");

is_deeply(
  [ $git->ls_files({ o => 1 }) ],
  [ 'foo/bar' ],
);

$git->add('.');
is_deeply(
  [ $git->ls_files ],
  [ 'foo/bar' ],
);

$git->commit({ message => "FIRST" });

my @rev_list =  
  $git->rev_list({ all => 1, quiet => 1, pretty => 'oneline' });
is(@rev_list, 1);
like($rev_list[0], qr/^[a-f\d]{40} FIRST$/);
  

