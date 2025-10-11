#!/bin/sh
# Schedule this script to download server lists and change to 1st recommended

# Configuration parameters
VPN_IF='wg4'
# List of IPs to randomly ping
IP0='8.8.8.8'
IP1='8.8.4.4'
IP2='1.1.1.1'
IP3='1.0.0.1'
IP4='208.67.222.222'
IP5='208.67.220.220'
IP6='9.9.9.9'
IP7='149.112.112.112'
IP8='195.46.39.39'
IP9='195.46.39.40'
IP10='45.90.28.165'
IP11='45.90.30.165'
IP12='156.154.70.1'
IP13='156.154.71.1'
IP14='8.26.56.26'
IP15='8.20.247.20'
IP16='64.6.64.6'
IP17='64.6.65.6'
IP18='209.244.0.3'
IP19='209.244.0.4'

if curl -o /tmp/nordvpn.json -s 'https://api.nordvpn.com/v1/servers/recommendations?&filters\[servers_technologies\]\[identifier\]=wireguard_udp&limit=10' >/dev/null 2>&1 && jq -er '.[0].station' /tmp/nordvpn.json >/dev/null 2>&1 ; then
    jq -r '.[] | .hostname, .station, (.technologies.[].metadata.[] | select(.name=="public_key") | .value)' /tmp/nordvpn.json | while read -r HOST_NAME && read -r SERVER_IP && read -r PUBLIC_KEY; do
        if [ "$(uci get network.${VPN_IF}server.endpoint_host)" != "$SERVER_IP" ]; then
            uci set "network.${VPN_IF}server.public_key"="$PUBLIC_KEY"
            uci set "network.${VPN_IF}server.endpoint_host"="$SERVER_IP"
            uci set "network.${VPN_IF}server.description"="$HOST_NAME"
            uci commit network
            echo "*** VPN server changed to $HOST_NAME ( $SERVER_IP ) ***"
            /etc/init.d/network reload
            sleep 60
            { eval ping -q -c 1 -W 5 "\$IP$(awk 'BEGIN { srand(); print int(rand()*10000000)%20 }')" -I "$VPN_IF" >/dev/null 2>&1 && echo '*** VPN connection is OK ***' && break; } || echo '*** VPN connection is not OK, trying another server... ***'
        fi
    done
fi
