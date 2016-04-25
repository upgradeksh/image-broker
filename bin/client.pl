#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use autodie;

use Gearman::Client;
use Storable qw( freeze );
use YAML::XS qw( LoadFile );
use FindBin qw( $Bin );

my $config  = LoadFile "$Bin/../conf/wmp-image-broker.yml";
my $client  = Gearman::Client->new(
    job_servers => [ $config->{gearman}{host} ],
);

my $mon_dir  = $config->{sync}{src_root};
my @excludes = map { '--exclude' . q{ } . $_ } @{ $config->{inotifywait}{exclude} };
my @events   = map { '-e'        . q{ } . $_ } @{ $config->{inotifywait}{events}  };

my $opts = '-m -r';
$opts .= " @excludes" if @excludes;
$opts .= " @events  " if @events;

open my $inotify, "inotifywait $opts $mon_dir |";

while (<$inotify>) {
    my ( $dir, $event, $file ) = split;
    my @events = split /,/, $event;

    print $file, "\n";
    my $task_set = $client->new_task_set;
    $task_set->add_task( 'sync_file' => freeze({ file => $dir . $file }) );
}
