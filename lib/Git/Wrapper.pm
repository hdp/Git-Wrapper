use strict;
use warnings;

package Git::Wrapper;

our $VERSION = '0.003';
use IPC::Open3 () ;
use Symbol;
use File::pushd;

sub new {
  my ($class, $arg, %opt) = @_;
  my $self = bless { dir => $arg, %opt } => $class;
  die "usage: $class->new(\$dir)" unless $self->dir;
  return $self;
}

sub dir { shift->{dir} }

my $GIT = 'git';

sub _opt {
  my $name = shift;
  $name =~ tr/_/-/;
  return length($name) == 1 
    ? "-$name"
    : "--$name"
  ;
}

sub _cmd {
  my $self = shift;

  my $cmd = shift;

  my $opt = ref $_[0] eq 'HASH' ? shift : {};

  my @cmd = $GIT;

  for (grep { /^-/ } keys %$opt) {
    (my $name = $_) =~ s/^-//;
    my $val = delete $opt->{$_};
    next if $val eq '0';
    push @cmd, _opt($name) . ($val eq '1' ? "" : "=$val");
  }
  push @cmd, $cmd;
  for my $name (keys %$opt) {
    my $val = delete $opt->{$name};
    next if $val eq '0';
    push @cmd, _opt($name) . ($val eq '1' ? "" : "=$val");
  }
  push @cmd, @_;
    
  #print "running [@cmd]\n";
  my @out;
  my @err;
  
  {
    my $d = pushd $self->dir;
    my ($wtr, $rdr, $err);
    $err = Symbol::gensym;
    my $pid = IPC::Open3::open3($wtr, $rdr, $err, @cmd);
    close $wtr;
    chomp(@out = <$rdr>);
    chomp(@err = <$err>);
    waitpid $pid, 0;
  };
  #print "status: $?\n";
  if ($?) {
    die Git::Wrapper::Exception->new(
      output => \@out,
      error  => \@err,
      status => $? >> 8,
    );
  }
    
  chomp(@out);
  return @out;
}

sub AUTOLOAD {
  my $self = shift;
  (my $meth = our $AUTOLOAD) =~ s/.+:://;
  return if $meth eq 'DESTROY';
  $meth =~ tr/_/-/;

  return $self->_cmd($meth, @_);
}

sub log {
  my $self = shift;
  my $opt  = ref $_[0] eq 'HASH' ? shift : {};
  $opt->{no_color} = 1;
  my @out = $self->_cmd(log => $opt, @_);

  my @logs;
  while (@out) {
    local $_ = shift @out;
    die "unhandled: $_" unless /^commit (\S+)/;
    my $current = Git::Wrapper::Log->new($1);
    $_ = shift @out;

    while (/^(\S+):\s+(.+)$/) {
      $current->attr->{lc $1} = $2;
      $_ = shift @out;
    }
    die "no blank line separating head from body" if $_;
    my $body = '';
    while (@out and length($_ = shift @out)) {
      s/^\s+//;
      $body .= "$_\n";
    }
    $current->body($body);
    push @logs, $current;
  }

  return @logs;
}

package Git::Wrapper::Exception;

sub new { my $class = shift; bless { @_ } => $class }

use overload (
  q("") => 'error',
  fallback => 1,
);

sub output { join "", map { "$_\n" } @{ shift->{output} } }
sub error  { join "", map { "$_\n" } @{ shift->{error} } } 
sub status { shift->{status} }

package Git::Wrapper::Log;

sub new { 
  my ($class, $id, %arg) = @_;
  return bless {
    id => $id,
    attr => {},
    %arg,
  } => $class;
}

sub id { shift->{id} }

sub attr { shift->{attr} }

sub body { @_ > 1 ? ($_[0]->{body} = $_[1]) : $_[0]->{body} }

sub date { shift->attr->{date} }

sub author { shift->attr->{author} }

1;
__END__

=head1 NAME

Git::Wrapper - wrap git(7) command-line interface

=head1 VERSION

  Version 0.003

=head1 SYNOPSIS

  my $git = Git::Wrapper->new('/var/foo');

  $git->commit(...)
  print for $git->log;

=head1 DESCRIPTION

Git::Wrapper provides an API for git(7) that uses Perl data structures for
argument passing, instead of CLI-style C<--options> as L<Git> does.

=head1 METHODS

Except as documented, every git subcommand is available as a method on a
Git::Wrapper object.

The first argument should be a hashref containing options and their values.
Boolean options are either true (included) or false (excluded).  The remaining
arguments are passed as ordinary command arguments.

  $git->commit({ all => 1, message => "stuff" });

  $git->checkout("mybranch");

Output is available as an array of lines, each chomped.

  @sha1s_and_titles = $git->rev_list({ all => 1, pretty => 'oneline' });

If a git command exits nonzero, a C<Git::Wrapper::Exception> object will be
thrown.  It has three useful methods:

=over

=item * error

error message

=item * output

normal output, as a single string

=item * status

the exit status

=back

The exception stringifies to the error message.

=head2 new

  my $git = Git::Wrapper->new($dir);

=head2 dir

  print $git->dir; # /var/foo

=head1 SEE ALSO

L<VCI::VCS::Git> is the git implementation for L<VCI>, a generic interface to
version-controle systems.

Git itself is at L<http://git.or.cz>.

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-git-wrapper@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Hans Dieter Pearcey, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
