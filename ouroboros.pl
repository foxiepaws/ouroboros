use Getopt::Long;
# use Ouroboros::Core;
use Ouroboros::Worker;
use YAML;
use Data::Dumper;
$mainconfig = YAML::LoadFile("./config.yml"); # Config("./config.yml");




foreach (@{$mainconfig->{logs}}) {
    $config = $_;
    if (fork == 0) {
        print Dumper $config;
        my $worker = Ouroboros::Worker->new($config,$mainconfig->{syslog});
        $worker->Run();
    } 
}

sleep 1 while() 


