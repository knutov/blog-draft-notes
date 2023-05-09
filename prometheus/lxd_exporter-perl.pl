#!/usr/bin/env perl
use Mojolicious::Lite;

plugin 'basic_auth';

use Data::Dumper;

our $login = 'prom'; # change it!
our $pass = 'pass'; # change it!

get '/metrics' => sub {
        my $self = shift;
        if ( $self->basic_auth( realm => sub { return 1 if "@_" eq "$login $pass" } ) ) {
                my $o = `lxc query /1.0/metrics`;
                return $self->render( text => $o );
        }
};

app->start;

# for debug:
# you can run it in `screen` with
# perl lxd_exporter-perl.pl daemon -m production -l http://*:9472
# you can add to /etc/rc.local something like
# cd /etc/prometheus && screen -dm bash -c '/usr/bin/perl lxd_exporter-perl.pl daemon -m production -l http://*:9472'

___END___

apt install curl ; export PERL_CPANM_OPT=" --notest " ; curl -L http://cpanmin.us -k | perl - --self-upgrade ; cpanm App::cpm
cpm  install -g Mojolicious::Lite Mojolicious::Plugin::BasicAuth
cat << HERE >> /etc/rc.local
screen -S lxd_exporter -dm  bash -c ' /usr/bin/run-one-constantly /usr/bin/perl /usr/local/bin/lxd_exporter-perl.pl daemon -m production -l http://*:9472'
HERE
screen -S lxd_exporter -dm  bash -c ' /usr/bin/run-one-constantly /usr/bin/perl /usr/local/bin/lxd_exporter-perl.pl daemon -m production -l http://*:9472'
