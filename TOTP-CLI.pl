#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Pod::Usage;
use Getopt::Long;

use FindBin;
use lib $FindBin::Bin;

use TOTP;
use Carp;
use MIME::Base64;
use feature 'say';

my %cfg = (
    help           => 0,
    subCommand     => undef,
    subCommandArgs => [],
    issuer         => '',
    period         => undef,
    secret         => undef,
    secret_length  => undef,
);

GetOptions(
    'help|h'          => \$cfg{help},
    'secret=s'        => \$cfg{secret},
    'issuer=s'        => \$cfg{issuer},
    'secret_length=i' => \$cfg{secret_length},
    'period=i'        => \$cfg{period},
    '<>' => sub {
        my ($arg) = @_;
        if ( not defined $cfg{subCommand} ) {
            $cfg{subCommand} = $arg;
        } else {
            push @{ $cfg{subCommandArgs} }, $arg;
        }
    } ) || pod2usage(2);
pod2usage(1) if $cfg{help};

if ( not defined $cfg{subCommand} ) {
    croak "Usage error: no subCommand was given";
}

my $subcommand = {
    createQR => sub {
        my ($id) = @_;
        my $totp = $cfg{secret} ? TOTP->new( secret => $cfg{secret} ) : TOTP->new( $cfg{secret_length} );
        say($totp->secret);
        my $qr = $totp->QR($cfg{issuer}, $id);
        _displayInFirefox($qr);
    },
    validate => sub {
        my ($code) = @_;
        unless($cfg{secret}){
            say('need secret');
            return;
        }
        my $codeIsValid = TOTP->new( secret => $cfg{secret} )->validate($code);
        say("code is ", $codeIsValid ? 'valid' : 'invalid');
    },
}->{ $cfg{subCommand} };
&$subcommand( @{ $cfg{subCommandArgs} } );

sub _displayInFirefox {
    my ($base64Image) = @_;
    my $html = '<img alt="OTP" src="data:image/png;base64, '.$base64Image.'">';
    return system('firefox -new-tab "data:text/html;base64,'.encode_base64($html, '').'"');
}

__END__

=head1 NAME

totp - command line to manage time-based one-time passwords

=head1 SYNOPSIS

totp [command]

Available Commands:

    createQR
      <id>              required; identificator, e.g. account name or email
      --issuer          optional; service or campany name
      --period          optional; defaults to 30 seconda
      --secret          optional; if not set a new secret is created
      --secret_length   optional; defaults to 32 chars "arbitrary length"
    validate token
      --secret          required;
      <code>

Flags:

    -h, --help         Print help
