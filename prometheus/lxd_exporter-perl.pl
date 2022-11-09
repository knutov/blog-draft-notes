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
