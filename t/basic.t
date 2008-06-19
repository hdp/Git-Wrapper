use strict;
use warnings;
use Test::More 'no_plan';

use File::Temp qw(tempdir);
use IO::File;
use Git::Wrapper;
use File::Spec;
use File::Path qw(mkpath);
use POSIX qw(strftime);
use Test::Deep;

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
my $date = strftime("%a %b %d %H:%M:%S %Y %z", localtime);

my @rev_list =  
  $git->rev_list({ all => 1, quiet => 1, pretty => 'oneline' });
is(@rev_list, 1);
like($rev_list[0], qr/^[a-f\d]{40} FIRST$/);
  
eval { $git->no_such_command };
ok(my $e = $@, "got an error");
like($e, qr/'no-such-command' is not a git-command/);

my @log = $git->log;
is(@log, 1, 'one log entry');
my $log = $log[0];
is($log->id, (split /\s/, $rev_list[0])[0], 'id');
is($log->body, "FIRST\n", "body");
is($log->date, $date, "date");
