package Audio::OSC;

use 5.006;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';

=head1 NAME

Audio::OSC - OpenSound Control client and server implementation

=head1 SYNOPSIS

  use Audio::OSC;
  
  # see below

=head1 DESCRIPTION

    OpenSound Control ("OSC") is a protocol for communication among computers,
    sound synthesizers, and other multimedia devices that is optimized for
    modern networking technology. 

    L<http://www.cnmat.berkeley.edu/OpenSoundControl/>

This suite of modules provides an implementation of the protocol in Perl,
according to version 1.0 (March 26, 2002) of the specification. 

To actually create an OSC client or server, take a look at L<Audio::OSC::Client> and  L<Audio::OSC::Server>. This module only provides several helper functions. Normally, there shouldn't be a need for you to use this module directly.

This is an alpha-quality release. Data structures and interfaces are subject to change.

=head1 DATA FORMAT

OSC data is represented in a form closely related to the original binary format.

=head2 MESSAGES

A message is an array reference containing an OSC address followed by zero or more pairs of type identifiers and data. Examples:

    ['/Fader', f, 0.2]

    ['/Synth/XY', i, 10, i, 200]

=head2 BUNDLES

A bundle is an array reference that contains the bundle identifier C<#bundle> and a timestamp, followed by zero or more messages. Examples:

    ['#bundle', 0.1, ['/Pitch', 'f', rand(1)]

    ['#bundle', 0.1, ['/Slider', 'f', $s],
                     ['/Synth/XY', 'i', $x, 'i', $y]

=head1 FUNCTIONS

=over

=item protocol()

Returns information about the version of the OSC protocol implemented. Currently C<OSC/1.0>. 

=cut

sub protocol {
    return "OSC/1.0";
}

=item types()

Returns information about the data types implemented. Currently C<bfis> (blobs, floats, ints and strings).

=cut

sub types {
    return "bfis";
}

our $_match_OSCString = <<EOT;
(?:[^\0]{4})*       # zero or more blocks of four non-ASCII-NULs
(?:
[^\0]{3}\0    |      # block padded with ASCII-NULs
[^\0]{2}\0{2} |
[^\0]{1}\0{3} |
\0{4}
)
EOT

=item decode($data)

Decodes binary OSC message or bundle data into a Perl data structure

=cut

sub decode {
    local $_;
    my ($data) = @_;    
    
    return undef unless $data;

    if ($data =~ /^\#bundle/) {
        return _decode_bundle($data);
    } else {
        return _decode_message($data);
    }
}

# format: ['#bundle', timestamp, [element1...], [element2...], ...]
sub _decode_bundle {
    my ($data) = @_;
    
    my $msg = [];
    
    # Get OSC target address
    $data =~ /^($_match_OSCString)(.*)/x || return undef;
    $data = $2; # discard '#bundle'
    push @$msg, '#bundle';
    
    my ($ts1, $ts2) = unpack('ll', $data);
    substr($data, 0, 8) = '';
    push @$msg, "$ts1.$ts2";
    
    while (length($data) > 0) {
        my $len = unpack('l', $data);
        substr($data, 0, 4) = '';
        push @$msg, decode(substr($data, 0, $len));
        substr($data, 0, $len) = '';
    }

    return $msg;
}

# format: [addr, type, data, type, data, ...]
sub _decode_message {
    local $_;
    my ($data) = @_;
    
    my $msg = [];
    
    # Get OSC target address
    $data =~ /^($_match_OSCString)(.*)/x || return undef;
    $data = $2;

    (my $addr = $1) =~ s/\0//g;
    push @$msg, $addr;
        
    # Get type string
    $data =~ /^($_match_OSCString)(.*)/x || return undef;
    $data = $2;
    (my $types = $1) =~ s/(^,|\0)//g;
    
    foreach (split //, $types) {
        # push type identifier
        push @$msg, $_;
        
      SWITCH: for ($_) {
            /i/ && do {
                push @$msg, unpack('l', $data);
                # remove this integer from remaining data
                substr($data, 0, 4) = '';
                last SWITCH;
            };
            /f/ && do {
                push @$msg, unpack('f', $data);
                # remove this float from remaining data
                substr($data, 0, 4) = '';
                last SWITCH;
            };
            /s/ && do {
                $data =~ /^($_match_OSCString)(.*)/x || return undef;
                $data = $2;
                (my $s = $1) =~ s/\0//g;
                push @$msg, $s;
                last SWITCH;
            };
            /b/ && do {
                my $len = unpack('l', $data);
                substr($data, 0, 4) = '';            
                
                push @$msg, substr($data, 0, $len);
                # blob is zero-padded
                substr($data, 0, $len + (4 - $len % 4)) = '';
                
                last SWITCH;
            };
             
            return undef;
        }
    }
    
    return $msg;
}

=item encode($data)

Encodes OSC messages or bundles into their binary representation

=cut

sub encode {
    local $_;
    my ($data) = @_;
    my $idx = 0;
    
    return undef unless $data && ref($data);
    
    my $msg;
    
    if ($data->[0] eq '#bundle') {
        my $msg = toString($data->[$idx++]) . (chr(0) x 7) . chr(1);
        
        $idx++; # time tag currently not implemented
        
        while ($idx <= $#$data) {
            my $e = encode($data->[$idx++]);
            $msg .= toInt(length($e)) . $e;
        }
        
        return $msg;
    }
    
    $msg = toString($data->[$idx++]);
    my ($types, $payload) = ('', '');
    
    # '<' because we need _two_ elements (type tag, data)
    while ($idx < $#$data) {
        my ($t, $d) = ($data->[$idx++], $data->[$idx++]);
        
        $t eq 'i' && do { $types .= 'i'; $payload .= toInt($d) };
        $t eq 'f' && do { $types .= 'f'; $payload .= toFloat($d) };
        $t eq 's' && do { $types .= 's'; $payload .= toString($d) };
        $t eq 'b' && do { $types .= 'b'; $payload .= toBlob($d) };
    }
    
    return $msg . toString(",$types") . $payload;
}

=item toInt($n)

Returns the binary representation of an integer in OSC format

=cut

sub toInt {
    my ($n) = @_;
    
    return undef unless defined $n;
    
    return pack 'l', $n;
}

=item toFloat($n)

Returns the binary representation of a floating point value in OSC format

=cut

sub toFloat {
    my ($n) = @_;
    
    return undef unless defined $n;
    
    return pack 'f', $n;
}

=item toString($str)

Returns the binary representation of a string in OSC format

=cut

sub toString {
    my ($str) = @_;
    
    return undef unless defined $str;
    
    # use bytes for UNICODE compatibility 
    return $str .  "\0" x (4 - length($str) % 4);
}

=item toBlob($d)

Returns the binary representation of a BLOB value in OSC format

=cut

sub toBlob {
    my ($d) = @_;

    return undef unless defined $d;
    
    return toInt(length($d)) . toString($d)
}

1;

=back

=head1 BUGS

Doesn't work with Unicode data. Remember to C<use bytes> if you use
Unicode Strings.

Time tags are currently not encoded.

=head1 SEE ALSO

The OpenSoundControl website at L<http://www.cnmat.berkeley.edu/OpenSoundControl/>

L<Audio::OSC::Client>

L<Audio::OSC::Server>

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Christian Renz <crenz@web42.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut