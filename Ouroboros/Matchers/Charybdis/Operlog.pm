package Ouroboros::Matchers::Charybdis::Operlog;


#
#
#

use strict;
use warnings;


BEGIN {
require Exporter;
our $VERSION = 0.01;
our @ISA = qw(Exporter);
our @EXPORT = qw(main);
our @EXPORT_FAIL = qw(setup ouro_oper ouro_failed_oper)
}


my $datetime = qr/(?<year>\d\d\d\d)\/(?<month>\d\d?)\/(?<day>\d\d?)\s(?<time>\d\d.\d\d)/;
my $hostmask = qr/(?<hostmask>(?<nick>.*?)!(?<ident>~?(?:.*?))@(?<host>.*?))/;

sub setup {
    my $module = __PACKAGE__;
    no strict 'refs';
    return grep { defined &{"$module\::$_"} } grep {/ouro_/} keys %{"$module\::"}
}

sub main {
    my $line = shift;
    my @funcs = setup();
    no strict 'refs';
    foreach (@funcs) {
        $_ = &{$_}($line);
        if (defined) {
            return $_
        }
    }
    # default return
    return {facl => "DAEMON", sev => "INFO", msg => $line}
}

sub ouro_oper {
    my $line = shift;
    return undef unless($line =~ /$datetime OPER (?<oline>.*?) by $hostmask \((?<address>.*?)\)/);
    my $message = $+{oline} . " oper from " . $+{address} . " (" . $+{hostmask} . ")";
    return {facl => "auth", sev => "notice", msg => $message};
}

sub ouro_failed_oper {
    my $line = shift;
    return undef unless($line =~ /$datetime FAILED OPER \((?<oline>.*?)\) by \($hostmask\) \((?<address>.*?)\)/);
    my $message = $+{oline} . " BAD oper from " . $+{address} . " (" . $+{hostmask} . ")";
    return {facl => "auth", sev => "notice", msg => $message};
}

1;
