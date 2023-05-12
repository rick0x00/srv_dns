#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 05 fev 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: srv_dns                                           #
# Description: Tool for help in the creation of DNS servers  #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_dns     #
# Remote repository 2: https://gitlab.com/rick0x00/srv_dns     #
# ============================================================ #

#################################################
# start complement definitions functions

function messenger() {
    echo "==================================================="
    echo " $* "
    echo "==================================================="
}

# end complement definitions functions
#################################################
# start main definitions functions
function stat_services() {
    messenger "Start Services"
    service named stop
    service named start
    service named status
}

function show_dscodes() {
    messenger "Show DS code, Keytag and Digest"
    dig @127.0.0.1 +norecurse "$domain". DNSKEY | dnssec-dsfromkey -f - "$domain"    
}

# end main definitions functions
#################################################
# start main executions of code

stat_services
show_dscodes
service named stop

/usr/sbin/named -g -c /etc/bind/named.conf -u bind
