package Ouroboros::Worker;

use strict;
use warnings;
use utf8;


use Sys::Syslog qw(:standard :macros :extended);
use POE qw(Wheel::FollowTail);

use Data::Dumper;

sub new ($$$){
    my $class = shift;
    my ($config, $syslogconfig) = @_;
    return bless {config => $config, syslogconfig => $syslogconfig}, $class;
}

sub config {
    my $self = shift;
    return $self->{config};
}

sub syslogconfig {
    my $self = shift;
    return $self->{syslogconfig};
}

sub log {
    my $self = shift;
    my $line = shift;
    my $module = $self->{config}->{matcher};
    $module =~ s/(.*)::(?<entry>.*?)\(\)$/$1/;
    if (defined $+{entry}) {
        my $entry = $+{entry};
        eval { 
            no strict 'refs'; 
            my $log = &{"$module\::$entry"}($line);
            my $sev = $log->{facl}."|".$log->{sev}; 
            syslog("$sev","%s",$log->{msg})
        }
    } else {
        eval { 
            no strict 'refs'; 
            my $log = &{"$module\::main"}($line); 
            my $sev = $log->{facl}."|".$log->{sev}; 
            syslog("$sev","%s",$log->{msg})
        }
    }
    warn $@ if $@;
}

# the entry point that is actually ran from
sub Run {
    my $self = shift;
    $self->LoadMatcher();
    $self->SetupSyslog();

    POE::Session->create(
        inline_states => {
            _start => sub { $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                    Filename => $self->{config}->{file},
                    InputEvent => 'got_line') },
            got_line => sub {
                $self->log($_[ARG0]);
            }
            }
        );
    POE::Kernel->run();
}

sub SetupSyslog {
    my $self = shift;
    $0 = "ouro-".$self->{config}->{ident}; # for some reason syslog() isn't able to log
                                   # to auth.log and friends when i call
                                   # openlog(). this is a ugly work around that
                                   # enables the ident to show up correctly.
}

sub LoadMatcher {
    my $self = shift;
    if (defined($self->{config}->{matcher})) {
        my $module = $self->{config}->{matcher};
        $module =~ s/(.*)::(?<entry>.*?)\(\)$/$1/;
        eval "require $module";
        unless ($@) {
            if (defined $+{entry}) {
                no strict 'refs';
                eval { print Dumper &{"$module\::".$+{entry} }("test") };
                if ($@) {
                     warn 'Module Failed to Load: $@';
                     exit
                }
            } else {
                no strict 'refs';
                eval { print Dumper &{"$module\::main"}("test") };
                if ($@) {
                    warn 'Module Failed to load: $@';
                    exit
                }
            }
        }
    }
}

1;
