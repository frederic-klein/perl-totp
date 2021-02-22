#!/usr/bin/perl -w
package TOTP;

use Moose;

# sudo apt-get install libdigest-hmac-perl
use Digest::HMAC_SHA1 qw/ hmac_sha1_hex /;
# sudo apt-get install libimager-qrcode-perl
use Imager::QRCode;
# libcrypt-random-seed-perl
use Crypt::Random::Seed;
use MIME::Base64;

my $source = Crypt::Random::Seed->new( Only => ['/dev/random'] );

has 'secret' => (
    is  => 'ro',
    isa => 'Str',
);

has 'period' => (
    is  => 'ro',
    isa => 'Int',
    default => 30,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    if ( @_ == 0 ) {
        return $class->$orig( secret => _generateSecret() );
    }
    elsif ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( secret => _generateSecret( $_[0] ) );
    }
    else {
        return $class->$orig(@_);
    }
};

sub validate {
    my ( $this, $code ) = @_;
    return $this->currentCode() == $code;
}

sub _generateSecret {
    my ($secret_length) = @_;
    $secret_length //= 32;
    my $secret;
    for (1..$secret_length) {
        $secret .= getChar();
    }
    return $secret;
}

sub getChar {
    my @validCharacters = ("A".."Z", "2".."7");
    return $validCharacters[ ord($source->random_bytes(1)) % scalar(@validCharacters) ];
}

sub currentCode {
    my ($this) = @_;

    my $decoded_secret = readpipe("echo '".$this->secret."' | base32 --decode -w 0");
    my $hmac = hmac_sha1_hex(pack('H*', sprintf("%016x", int(time() / $this->period))), $decoded_secret);
    my $encrypted = hex(substr($hmac, hex(substr($hmac, -1)) * 2, 8)) & 0x7fffffff;
    return sprintf("%06d", $encrypted % 1000000);
}

sub QR {
    my ($this, $issuer, $id) = @_;
    my $qrcode = Imager::QRCode->new(
        size          => 4,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    );

    my $otpURI = 'otpauth://totp/';
    $otpURI .= $issuer ? $issuer.':'.$id.'?secret='.$this->secret.'&issuer='.$issuer : $id.'?secret='.$this->secret;
    my $img = $qrcode->plot($otpURI);

    my $data;
    $img->write(type=>'png', data=>\$data) or croak $img->errstr;

    return encode_base64($data, '');
}

no Moose;
__PACKAGE__->meta->make_immutable;
