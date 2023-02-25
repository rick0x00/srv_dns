FROM debian:11

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
# start set variables

ARG dns_type="master"
ARG master_dns_ipv4="192.168.0.2"
ARG slave_dns_ipv4="192.168.0.3"
ARG domain="example.com.br"

ENV dns_type=${dns_type}
ENV master_dns_ipv4=${master_dns_ipv4}
ENV slave_dns_ipv4=${slave_dns_ipv4}
ENV domain=${domain}

# end set variables
################################################################################################

RUN apt update

#RUN apt install -y cron iputils-ping iproute2 net-tools vim nano traceroute systemctl

COPY ./build.sh /tmp/
RUN bash /tmp/build.sh

WORKDIR /var/lib/bind/
VOLUME ["/etc/bind", "/var/lib/bind"]
EXPOSE 53/udp 53/tcp 953/tcp

COPY ./ds_code.sh /etc/bind/
COPY ./init.sh /etc/bind/


ENTRYPOINT ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]
#ENTRYPOINT ["bash", "/etc/bind/init.sh"]
#CMD ["bash", "/etc/bind/ds_codes.sh"]
#ENTRYPOINT ["/usr/sbin/cron","-f"]
