#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use autodie;

use Gearman::Client;
use Storable qw( freeze );
use WebService::Slack::WebApi;

my $job_svr = '127.0.0.1';
my $client  = Gearman::Client->new(
    job_servers => [ $job_svr ],
);

my $timeout  = 5;
my $echo_str = 'ok';
my $task_set = $client->new_task_set;

eval {
    local $SIG{ALRM} = sub { die "timed out : [$timeout]\n" };
    alarm $timeout;
    $task_set->add_task( 'echo' => freeze({ str => $echo_str }), {
        on_complete => sub { print ${ $_[0] }, "\n" },
        on_fail     => sub { print "err\n" },
    });
};

if ($@) {
    $ENV{HTTP_PROXY} = 'http://somewhere:8080';

    my $token = 'xoxp-1234567890-1234567890-1234567890-1234567890';
    my $slack = WebService::Slack::WebApi->new(
        token => $token,
        opt   => {
            env_proxy => 1,
        },
    );

    my $result = $slack->chat->post_message(
        channel     => 'slack-test',
        username    => 'system',
        attachments => [
            {
                fallback => 'Required plain-text summary of the attachment.',
                color    => 'danger',
                pretext  => 'Optional text that appears above the attachment block',

                author_name => 'Bobby Tables',
                author_link => 'http://flickr.com/bobby/',
                author_icon => 'http://flickr.com/icons/bobby.jpg',

                title       => 'Slack API Documentation',
                title_link  => 'https://api.slack.com/',

                text => 'Optional text that appears within the attachment',

                fields => [
                    {
                        title => 'Priority',
                        value => 'High',
                        short => Types::Serialiser::true,
                    },
                    {
                        title => 'in charge of',
                        value => 'John Kang',
                        short => Types::Serialiser::false,
                    },
                    {
                        title => 'date',
                        value => '2015-01-11 23:44:12',
                        short => Types::Serialiser::false,
                    },
                ],
                image_url=> 'http://my-website.com/path/to/image.jpg',
                thumb_url=> 'http://example.com/path/to/thumb.png',
            }
        ], 
    );

    warn "$result->{error}\n" if $result->{error};
    exit 255;
}

$task_set->wait;
