#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use File::Rsync;
use FindBin qw( $Bin );
use Gearman::Worker;
use Storable qw( thaw );
use YAML::XS qw( LoadFile );

my $config = LoadFile "$Bin/../conf/wmp-image-broker.yml";
my $worker = Gearman::Worker->new(
    job_servers => [ $config->{gearman}{host} ],
);

my $src_root = $config->{sync}{src_root};
my $dst_root = $config->{sync}{dst_root};

$worker->register_function( sync_file => \&sync_file );
$worker->register_function( echo      => \&echo );
$worker->work while 1;

sub sync_file {
    my $arg  = thaw( $_[0]->arg );
    my $file = $arg->{file};

    print "trying to rsync [$file]\n";

    ( my $rel_src = $file ) =~ s{($src_root/?)}{$1./};
    my $rsync = File::Rsync->new(
        compress => 0,
        relative => 1,
        times    => 1,
        itemize_changes => 1,
        src      => $rel_src,
        dst      => $dst_root,
    );

    my ($cmd) = $rsync->getcmd;
    print "@$cmd\n";

    $rsync->exec;
    ## cd+++++++++
    my $rsync_item = ${$rsync->out}[0];

    if ( $rsync_item =~ /\+{9}/ ) {
        my $cdn = WMP::CDN::Infralab->new(
            root => '/data/isilon/image',
            file => $file,
        );
        $cdn->purge;
    } 
    
}

sub echo {
    my $arg = thaw( $_[0]->arg );
    my $str = $arg->{str};

    return $str;
}
