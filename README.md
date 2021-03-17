# perl-totp
demo for google authenticator totp (linux only)

## requirements

This is just a little demonstration and has no intention to be cross plattform. It uses some systemcalls, to require less perl packages and expects firefox to be present (for displaying the qr tag).

Additional packages needed:
* libmoose-perl
* libdigest-hmac-perl
* libimager-qrcode-perl
* libcrypt-random-seed-perl

---

    sudo apt-get install libmoose-perl libdigest-hmac-perl libimager-qrcode-perl libcrypt-random-seed-perl

## usage

    perl TOTP-CLI.pl --help
    perl TOTP-CLI.pl createQR --issuer 'your service name' someuser@somemail.com
    perl TOTP-CLI.pl --secret ABCDEFGHIJKL validate 012345
