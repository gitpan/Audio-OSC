package Audio::OSC::Server;

use 5.006;
use strict;
use warnings;
use IO::Socket;
use Audio::OSC;

our @ISA = qw();

our $VERSION = '0.01';

=head1 NAME

Audio::OSC::Server - OpenSound Control server implementation

=head1 SYNOPSIS

  use Audio::OSC::Server;
  use Data::Dumper qw(Dumper);

  sub dumpmsg {
      my ($sender, $message) = @_;
      
      print "[$sender] ", Dumper $message;
  }

  my $server = Audio::OSC::Server->new(Port => 7777, Handler => \&dumpmsg) or
      die "Could not start server: $@\n";

  $server->readloop();

=head1 DESCRIPTION

This module implements an OSC server (right now, blocking and not-yet multithreaded...) receiving messages via UDP.
Once a message is received, the server calls a handler
routine. The handler receives the host name of the sender as well as the (decoded) OSC message or bundle.

=head1 METHODS

=over

=item new(Port => $port, Name => $name, Handler => \&handler)

Creates a new server object. Default port is 7123, default name is C<Audio-OSC-Server:7123>, default handler is undef.

Returns undef on failure (in this case, $@ is set).

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = {};

    $self->{PORT} = $opts{Port} || 7123;
    $self->{NAME} = $opts{Name} || 'Audio-OSC-Server:' . $self->{PORT};
    $self->{HANDLER} = $opts{Handler} || undef;

    $self->{SOCKET} =
        IO::Socket::INET->new(LocalPort => $self->{PORT},
                              Proto     => 'udp')
        or return undef; # error is in $@

    bless $self, $class;
}

=item name()

Returns the name of the server

=cut

sub name {
    my $self = shift;
    
    return $self->{NAME}
}

=item port()

Returns the port the server is listening at

=cut

sub port {
    my $self = shift;

    return $self->{PORT}
}

=item readloop()

Enters a loop waiting for messages. Once a message is received, the server will
call the handler subroutine, if defined.

=cut

sub readloop {
    my $self = shift;

    my $MAXLEN = 1024;
    my ($msg, $host);

    while ($self->{SOCKET}->recv($msg, $MAXLEN)) {
        my($port, $ipaddr) = sockaddr_in($self->{SOCKET}->peername);
        $host = gethostbyaddr($ipaddr, AF_INET) || '';
        
        $self->{HANDLER}->($host, Audio::OSC::decode($msg))
            if defined $self->{HANDLER};       
        
        return if ($msg =~ /exit/);
    } 
}

1;

=back

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
