package Ouroboros::Core;

use strict;
use warnings;
use feature 'switch';
use YAML;

# use POE qw(Wheel::FollowTail)
# use Sys::Syslog qw(:standard :macros :extended)


# debug
use Data::Dumper;

BEGIN {
    require Exporter;
    our @ISA = qw(Exporter);
    our $VERSION = 0.01;
    our @EXPORT = qw(Config);
    our @EXPORT_FAIL = qw(_ouro_log_warn)
}

our $config;
our @failed_matchers;


# default exported functions
sub Config ($) {
    my $configfile = shift;
    $config = YAML::LoadFile($configfile);
    LoadMatchers();
    _ouro_log_warn($_->{matcher}." failed to load, ".$_->{why},1) foreach @failed_matchers;
    eval { print Dumper Ouroboros::Matchers::Charybdis::Operlog::main("test") } # test one of the matchers i know i use 
}


# internal funcs that can be exported.
sub LoadMatchers () {
    foreach (@{$config->{logs}}) {
        print Dumper $_;
        if (defined($_->{matcher})) {
            my $module = $_->{matcher};
            $module =~ s/(.*)::(?<entry>.*?)\(\)$/$1/;
            print "trying to load in $module\n";
            eval "require $module";
            unless ($@) {
                if (defined $+{entry}) {
                    no strict 'refs';
                    eval { print Dumper &{"$module\::".$+{entry} }("test") };
                    if ($@) {
                        _ouro_log_warn($@);
                        push @failed_matchers, {matcher => $_->{matcher}, why => $@};
                    }
                } else {
                    no strict 'refs';
                    eval { print Dumper &{"$module\::main"}("test") };
                    if ($@) {
                        _ouro_log_warn($@);
                        push @failed_matchers, {matcher => $_->{matcher}, why => $@};
                    }
                }
            }
        }
    }
    return;
}



# internal use functions
sub _ouro_log_warn ($;$) {
    my $msg = shift;
    my $writelog = shift;
    if ($writelog) {
        warn "[warning+logged] $msg"
    } else {
        warn "[warning] $msg";
    }
}




1;
