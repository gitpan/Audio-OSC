package Audio::OSC::Client;

use 5.006;
use strict;
use warnings;
use IO::Socket;
use Audio::OSC;

our @ISA = qw();

our $VERSION = '0.01';

=head1 NAME

Audio::OSC::Client - OpenSound Control client implementation

=head1 SYNOPSIS

  use Audio::OSC::Client;

  my $client = Audio::OSC::Client->new(Host => "192.168.3.240", Port => 7777)
      or die "Could not start client: $@\n";
 
  # This is a very slow fade-in...
  for (0..100) {
      $client->send(['/Main/Volume', 'f', $_ / 100]);
      sleep(1);
  }

=head1 DESCRIPTION

This module implements an OSC client sending messages via UDP.

=head1 METHODS

=over

=item new(Host => Host, Port => $port, Name => $name)

Creates a new client object. The default host is localhost, the default port 7123 and the default name C<Audio-OSC-Client talking to localhost:7123>.

Returns undef on failure (in this case, $@ is set).

=cut 

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = {};

    $self->{HOST} = $opts{Host} || "localhost";
    $self->{PORT} = $opts{Port} || 7123;
    $self->{NAME} = $opts{Name} || 'Audio-OSC-Client talking to ' .
        $self->{HOST} . ':' . $self->{PORT};

    $self->{SOCKET} =
        IO::Socket::INET->new(PeerAddr  => $self->{HOST},
                              PeerPort  => $self->{PORT},
                              Proto     => 'udp')
        or return undef; # error is in $@

    bless $self, $class;
}

=item name()

Returns the name of the client

=cut

sub name {
    my $self = shift;
    
    return $self->{NAME}
}

=item host()

Returns the server host we are talking to

=cut

sub host {
    my $self = shift;
    
    return $self->{HOST};
}

=item port()

Returns the server port we are talking to

=cut

sub port {
    my $self = shift;

    return $self->{PORT}
}

=item send($data)

Sends an OSC message or bundle to the server

=cut

sub send {
    my $self = shift;
    my ($data) = @_;
    
    $self->{SOCKET}->send(Audio::OSC::encode($data));
}

1;

=head1 SEE ALSO

The OpenSoundControl website: http://www.cnmat.berkeley.edu/OpenSoundControl/

L<Audio::OSC>

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Christian Renz <crenz@web42.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

