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

dnstype="master"
masterdnsipv4="192.168.0.2"
slavednsipv4="192.168.0.3"
domain="example.com.br"

hostname=$(hostname)
hostnameips=$(hostname -I)
hostnamefisrtipv4=$(echo "$masterdnsipv4" | cut -d" " -f1)
reversehostnamefisrtipv4=$(echo $hostnamefisrtipv4 | cut -d"." -f3).$(echo $hostnamefisrtipv4 | cut -d"." -f2).$(echo $hostnamefisrtipv4 | cut -d"." -f1)
endhostnamefisrtipv4=$(echo $hostnamefisrtipv4 | cut -d"." -f4)
endbyteipv4masterdns=$(echo $masterdnsipv4 | cut -d"." -f4)
endbyteipv4slavedns=$(echo $slavednsipv4 | cut -d"." -f4)
serialdate=$(date +'%Y%m%d')

# end set variables
################################################################################################
# start definition functions
#################################################
# start main definitions functions

# end main definitions functions
#################################################
# end definition functions
################################################################################################
# start argument reading

# end argument reading
################################################################################################
# start main executions of code

function set_good_dns() {
    echo "Establishing Temporary Good DNS"
    cp /etc/resolv.conf /etc/resolv.conf.bkp_$(date --iso-8601='s')
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
}

function install_bind() {
    echo "Install BIND"
    apt update
    apt install -y bind9 bind9utils bind9-doc dnsutils
}

function set_localhost_dns() {
    echo "Establishing Localhost DNS"
    cp /etc/resolv.conf /etc/resolv.conf.bkp_$(date --iso-8601='s')
    echo "nameserver 127.0.0.1
    search localhost" > /etc/resolv.conf
}

function configure_etc_hosts() {
    echo "Configure /etc/hosts"
    cp /etc/hosts /etc/hosts.bkp_$(date --iso-8601='s')
    echo "" >> /etc/hosts
    echo "# --- START DNS MAPPING ---" >> /etc/hosts
    echo "$hostnamefisrtipv4 $hostname.$domain" >> /etc/hosts
    echo "# --- BEGIN DNS MAPPING ---" >> /etc/hosts
    echo "" >> /etc/hosts
}

function mk_workdir() {
    echo "Making Workdir"
    mkdir -p /var/lib/bind/$domain/db /var/lib/bind/$domain/keys
    chown root:bind -R /var/lib/bind/*
    chmod 770 -R /var/lib/bind/*
}

function mk_zone_file() {
    if [ $dnstype = "master" ]; then
        echo "Making Zone files"
        echo ';
        ; BIND data file for local loopback interface
        ;
        $TTL	604800
        @	IN	SOA'"	dns.$domain. root.$domain. "'(
                    '"$serialdate"'		; Serial
                    604800		; Refresh
                    86400		; Retry
                    2419200		; Expire
                    604800 )	; Negative Cache TTL
        ;'"
                    IN	NS	ns1.$domain.
                    IN	NS	ns2.$domain.

        dns			IN	A	$masterdnsipv4
        dns			IN	A	$slavednsipv4	

        ns1			IN	A	$masterdnsipv4
        ns2			IN	A	$slavednsipv4	

        $hostname	IN	A	$hostnamefisrtipv4

        " > /var/lib/bind/$domain/db/db.$domain

        echo ';
        ; BIND reverse data file for local loopback interface
        ;
        $TTL	604800
        @	IN	SOA'"	dns.$domain. root.$domain. "'(
                    '"$serialdate"'		; Serial
                    604800		; Refresh
                    86400		; Retry
                    2419200		; Expire
                    604800 )	; Negative Cache TTL
        ;'"
                    IN	NS	ns1.$domain.
                    IN	NS	ns2.$domain.

        $endbyteipv4masterdns			IN	PTR ns1.$domain.
        $endbyteipv4slavedns			IN	PTR ns2.$domain.

        $endhostnamefisrtipv4	IN	PTR $hostname.$domain.
        " > /var/lib/bind/$domain/db/db.$reversehostnamefisrtipv4

        echo "Implement DNSSEC"
        # Create our initial keys
        cd /var/lib/bind/$domain/keys/
        #sudo dnssec-keygen -a RSASHA256 -b 2048 -f KSK "$domain"
        #sudo dnssec-keygen -a RSASHA256 -b 1280 "$domain"

        dnssec-keygen -a NSEC3RSASHA1 -b 2048 -n ZONE $domain
        dnssec-keygen -f KSK -a NSEC3RSASHA1 -b 4096 -n ZONE $domain

        # Set permissions so group bind can read the keys
        chgrp bind /var/lib/bind/$domain/keys/*
        chmod g=r,o= /var/lib/bind/$domain/keys/*
        #sudo dnssec-signzone -S -z -o "$domain" "/var/lib/bind/$domain/db/db.$domain"
        #sudo dnssec-signzone -S -z -o "$domain" "/var/lib/bind/$domain/db/db.$reversehostnamefisrtipv4"
        #sudo chmod 644 /etc/bind/*.signed
    fi
}

function conf_named_conf_options() {
    echo "configure named.conf.options"
    cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bkp_$(date --iso-8601='s')

    if [ $dnstype = "master" ]; then
        echo 'options {
            directory "/var/cache/bind";
            dnssec-enable yes;
            dnssec-validation auto;
            listen-on { any; };
            listen-on-v6 { any; };
            allow-transfer {
                '"$slavednsipv4"';
            };
            allow-notify {
                '"$slavednsipv4"';
            };
            masterfile-format text;
            version "RR DNS Server";
        };
        ' > /etc/bind/named.conf.options
    elif [ $dnstype = "slave" ]; then
        echo 'options {
            directory "/var/cache/bind";
            dnssec-enable yes;
            dnssec-validation auto;
            listen-on { any; };
            listen-on-v6 { any; };
            allow-transfer { none; };
            masterfile-format text;
            version "RR DNS Server";
        };
        ' > /etc/bind/named.conf.options
    fi
}

function conf_named_conf_local() {
    echo "Configure /etc/bind/named.conf.local"
    echo "Specify Local Zone Files (DBs) directives"
    cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bkp_$(date --iso-8601='s')

    if [ $dnstype = "master" ]; then
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
        zone '"$reversehostnamefisrtipv4.in-addr.arpa"' {
            type master;
            file "'"/var/lib/bind/$domain/db/db.$reversehostnamefisrtipv4"'";
            key-directory "'"/var/lib/bind/$domain/keys/"'";
            auto-dnssec maintain;
            inline-signing yes;
            serial-update-method increment;
        };
        // --- BEGIN ORGANIZATION ZONES ---
        ' > /etc/bind/named.conf.local
    elif [ $dnstype = "slave" ]; then
        echo '
        // --- START ORGANIZATION ZONES ---
        // Forward Lookup Zone
        zone '"$domain"' {
            type slave;
            file "'"/var/lib/bind/$domain/db/db.$domain.signed"'";
            masters { '"$masterdnsipv4"'; };
            allow-notify { '"$masterdnsipv4"'; };
        };

        // Reverse Lookup Zone
        zone '"$reversehostnamefisrtipv4.in-addr.arpa"' {
            type slave;
            file "'"/var/lib/bind/$domain/db/db.$reversehostnamefisrtipv4.signed"'";
            masters { '"$masterdnsipv4"'; };
            allow-notify { '"$masterdnsipv4"'; };
        };
        // --- BEGIN ORGANIZATION ZONES ---
        ' > /etc/bind/named.conf.local
    fi
}

function stat_services() {
    echo "End Configurations"
    systemctl enable --now bind9
    systemctl restart bind9
    systemctl status bind9;
}

function show_dscodes() {
    echo "Show DS code, Keytag and Digest"
    dig @127.0.0.1 +norecurse "$domain". DNSKEY | dnssec-dsfromkey -f - "$domain"    
}

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