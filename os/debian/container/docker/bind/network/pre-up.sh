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

# ENABLE communication with containers of host

network_interface_bridge_name="dockerbridge"
network_parent_interface="wlo1"
ipv4_addr_interface="192.168.0.4/24"
ipv4_gateway_network="192.168.0.1"

ip link add $network_interface_bridge_name link $network_parent_interface type macvlan mode bridge
ip addr add $ipv4_addr_interface dev $network_interface_bridge_name
ip link set $network_interface_bridge_name up

#making route to containers
# making route to container dns_master
container_ipv4='192.168.0.2/32'
ip route add $container_ipv4 via $ipv4_gateway_network dev $network_interface_bridge_name