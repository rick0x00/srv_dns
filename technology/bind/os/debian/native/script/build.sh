#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 05 fev 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: srv_dns                                           #
# Description: Script for help in the creation of DNS servers  #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_dns     #
# Remote repository 2: https://gitlab.com/rick0x00/srv_dns     #
# ============================================================ #


################################################################################################
# start root user checking

if [ $(id -u) -ne 0 ]; then
    echo "Please use sudo or run the script as root."
    exit 1
fi

# end root user checking
################################################################################################
# start set variables

dns_type="master"
master_dns_ipv4="192.168.0.2"
slave_dns_ipv4="192.168.0.3"
domain="example.com.br"

hostname=$(hostname)
hostname_ips=$(hostname -I)
first_ipv4_hostname=$(echo "$master_dns_ipv4" | cut -d" " -f1)
firts_three_bytes_reverse_ipv4_hostname=$(echo $first_ipv4_hostname | cut -d"." -f3).$(echo $first_ipv4_hostname | cut -d"." -f2).$(echo $first_ipv4_hostname | cut -d"." -f1)
end_byte_ipv4_hostname=$(echo $first_ipv4_hostname | cut -d"." -f4)
end_byte_ipv4_master_dns=$(echo $master_dns_ipv4 | cut -d"." -f4)
end_byte_ipv4_slave_dns=$(echo $slave_dns_ipv4 | cut -d"." -f4)
serial_date=$(date +'%Y%m%d')

# end set variables
################################################################################################
# start definition functions
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

function set_good_dns() {
    messenger "Establishing Temporary Good DNS"
    cp /etc/resolv.conf /etc/resolv.conf.bkp_$(date --iso-8601='s')
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
}

function install_bind() {
    messenger "Install BIND"
    apt update
    apt install -y bind9 bind9utils bind9-doc dnsutils
}

function set_localhost_dns() {
    messenger "Establishing Localhost DNS"
    cp /etc/resolv.conf /etc/resolv.conf.bkp_$(date --iso-8601='s')
    echo "nameserver 127.0.0.1
    search localhost" > /etc/resolv.conf
}

function configure_etc_hosts() {
    messenger "Configure /etc/hosts"
    cp /etc/hosts /etc/hosts.bkp_$(date --iso-8601='s')
    echo "" >> /etc/hosts
    echo "# --- START DNS MAPPING ---" >> /etc/hosts
    echo "$first_ipv4_hostname $hostname.$domain" >> /etc/hosts
    echo "# --- BEGIN DNS MAPPING ---" >> /etc/hosts
    echo "" >> /etc/hosts
}

function mk_workdir() {
    messenger "Making Workdir"
    mkdir -p /var/lib/bind/$domain/db /var/lib/bind/$domain/keys
    chown root:bind -R /var/lib/bind/*
    chmod 770 -R /var/lib/bind/*
}

function mk_zone_file() {
    if [ $dns_type = "master" ]; then
        messenger "Making Zone files"
echo ';
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA'"	dns.$domain. root.$domain. "'(
            '"$serial_date"'		; Serial
            604800		; Refresh
            86400		; Retry
            2419200		; Expire
            604800 )	; Negative Cache TTL
;'"
            IN	NS	ns1.$domain.
            IN	NS	ns2.$domain.

dns			IN	A	$master_dns_ipv4
dns			IN	A	$slave_dns_ipv4	

ns1			IN	A	$master_dns_ipv4
ns2			IN	A	$slave_dns_ipv4	

$hostname	IN	A	$first_ipv4_hostname

" > /var/lib/bind/$domain/db/db.$domain

echo ';
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA'"	dns.$domain. root.$domain. "'(
            '"$serial_date"'		; Serial
            604800		; Refresh
            86400		; Retry
            2419200		; Expire
            604800 )	; Negative Cache TTL
;'"
            IN	NS	ns1.$domain.
            IN	NS	ns2.$domain.

$end_byte_ipv4_master_dns			IN	PTR ns1.$domain.
$end_byte_ipv4_slave_dns			IN	PTR ns2.$domain.

$end_byte_ipv4_hostname	IN	PTR $hostname.$domain.
" > /var/lib/bind/$domain/db/db.$firts_three_bytes_reverse_ipv4_hostname

        messenger "Implement DNSSEC"
        # Create our initial keys
        cd /var/lib/bind/$domain/keys/
        #sudo dnssec-keygen -a RSASHA256 -b 2048 -f KSK "$domain"
        #sudo dnssec-keygen -a RSASHA256 -b 1280 "$domain"

        dnssec-keygen -a ECDSAP256SHA256 -b 2048 -n ZONE $domain
        dnssec-keygen -f KSK -a ECDSAP256SHA256 -b 4096 -n ZONE $domain

        # Set permissions so group bind can read the keys
        chgrp bind /var/lib/bind/$domain/keys/*
        chmod g=r,o= /var/lib/bind/$domain/keys/*
        #sudo dnssec-signzone -S -z -o "$domain" "/var/lib/bind/$domain/db/db.$domain"
        #sudo dnssec-signzone -S -z -o "$domain" "/var/lib/bind/$domain/db/db.$firts_three_bytes_reverse_ipv4_hostname"
        #sudo chmod 644 /etc/bind/*.signed
    fi
}

function conf_named_conf_options() {
    messenger "configure named.conf.options"
    cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bkp_$(date --iso-8601='s')

    if [ $dns_type = "master" ]; then
        echo 'options {
            recursion yes;
            directory "/var/cache/bind";
            dnssec-enable yes;
            dnssec-validation auto;
            listen-on { any; };
            listen-on-v6 { any; };
            allow-transfer {
                '"$slave_dns_ipv4"';
            };
            allow-notify {
                '"$slave_dns_ipv4"';
            };
            masterfile-format text;
            version "DNS Server";
        };
        ' > /etc/bind/named.conf.options
    elif [ $dns_type = "slave" ]; then
        echo 'options {
            recursion yes;
            directory "/var/cache/bind";
            dnssec-enable yes;
            dnssec-validation auto;
            listen-on { any; };
            listen-on-v6 { any; };
            allow-transfer { none; };
            masterfile-format text;
            version "DNS Server";
        };
        ' > /etc/bind/named.conf.options
    fi
}

function conf_named_conf_local() {
    messenger "Configure /etc/bind/named.conf.local"
    messenger "Specify Local Zone Files (DBs) directives"
    cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bkp_$(date --iso-8601='s')

    if [ $dns_type = "master" ]; then
        echo '
        // --- START ORGANIZATION ZONES ---
        // Forward Lookup Zone
        zone '"$domain"' {
            type master;
            file "'"/var/lib/bind/$domain/db/db.$domain"'";
            key-directory "'"/var/lib/bind/$domain/keys/"'";
            auto-dnssec maintain;
            inline-signing yes;
            serial-update-method increment;
        };

        // Reverse Lookup Zone
        zone '"$firts_three_bytes_reverse_ipv4_hostname.in-addr.arpa"' {
            type master;
            file "'"/var/lib/bind/$domain/db/db.$firts_three_bytes_reverse_ipv4_hostname"'";
            key-directory "'"/var/lib/bind/$domain/keys/"'";
            auto-dnssec maintain;
            inline-signing yes;
            serial-update-method increment;
        };
        // --- BEGIN ORGANIZATION ZONES ---
        ' > /etc/bind/named.conf.local
    elif [ $dns_type = "slave" ]; then
        echo '
        // --- START ORGANIZATION ZONES ---
        // Forward Lookup Zone
        zone '"$domain"' {
            type slave;
            file "'"/var/lib/bind/$domain/db/db.$domain.signed"'";
            masters { '"$master_dns_ipv4"'; };
            allow-notify { '"$master_dns_ipv4"'; };
        };

        // Reverse Lookup Zone
        zone '"$firts_three_bytes_reverse_ipv4_hostname.in-addr.arpa"' {
            type slave;
            file "'"/var/lib/bind/$domain/db/db.$firts_three_bytes_reverse_ipv4_hostname.signed"'";
            masters { '"$master_dns_ipv4"'; };
            allow-notify { '"$master_dns_ipv4"'; };
        };
        // --- BEGIN ORGANIZATION ZONES ---
        ' > /etc/bind/named.conf.local
    fi
}

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
# end definition functions
################################################################################################
# start argument reading

# end argument reading
################################################################################################
# start main executions of code


set_good_dns
install_bind
set_localhost_dns
configure_etc_hosts
mk_workdir
mk_zone_file
conf_named_conf_options
conf_named_conf_local
stat_services
show_dscodes