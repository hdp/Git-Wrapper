use strict;
use warnings;

package Git::Wrapper;

our $VERSION = '0.001';

sub new {
  my ($class, $arg) = @_;
  my $self = bless $arg => $class;
  die "usage: $class->new({ dir => '/path/to/directory' })" unless $self->dir;
  return $self;
}

sub dir { shift->{dir} }

use File::pushd;

my $GIT = 'git';

sub _opt {
  my $name = shift;
  return length($name) == 1 
    ? "-$name"
    : "--$name"
  ;
}

sub AUTOLOAD {
  my $self = shift;
  (my $meth = our $AUTOLOAD) =~ s/.+:://;
  return if $meth eq 'DESTROY';
  $meth =~ tr/_/-/;

  my $opt = ref $_[0] eq 'HASH' ? shift : {};

  my @cmd = $GIT;

  for (grep { /^-/ } keys %$opt) {
    (my $name = $_) =~ s/^-//;
    my $val = delete $opt->{$_};
    next if $val eq '0';
    push @cmd, _opt($name) . ($val eq '1' ? "" : "=$val");
  }
  push @cmd, $meth;
  for my $name (keys %$opt) {
    my $val = delete $opt->{$name};
    next if $val eq '0';
    push @cmd, _opt($name) . ($val eq '1' ? "" : "=$val");
  }
  push @cmd, @_;
    
  #print "running [@cmd]\n";
  my @out = do {
    my $d = pushd $self->dir;
    readpipe(join " ", map { "\Q$_\E" } @cmd);
  };
  #print "status: $?\n";
  exit $? if $?;
  chomp(@out);
  return @out;
}

1;
__END__

=head1 NAME

Git::Wrapper - wrap git(7) command-line interface

=head1 VERSION

  Version 0.001

=head1 SYNOPSIS

  my $git = Git::Wrapper->new({ dir => "/var/foo" });

  $git->commit(...)
  $git->log

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

This is intentionally minimal; I don't know yet what kind of post-processing
will be useful.  Expect this to change in future releases.

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
