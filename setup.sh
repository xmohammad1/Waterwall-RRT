#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

apt update
sleep 0.5
apt-get install iproute2 -y
sleep 0.5
apt install netplan.io -y
sleep 0.5


echo "1. Kharej 1"
echo "2. Kharej 2"
echo "3. kharej 3"
echo "4. Iran"
echo "5. tunnel Gostv3"
echo "6. install Sanai X-ui"
echo "7. install Alireza X-ui"
# Prompt user for IP addresses
read -p "Select number : " choices
if [ "$choices" -eq 4 ]; then
   ipv4_address=$(curl -s https://api.ipify.org)
   echo "Iran IPv4 is : $ipv4_address"
   read -p "How many kharej servers you have? " num_servers
   number = 4
   for (( i=1; i<=$num_servers; i++ ))
   do
      read -p "Enter the remote IP address for server $i: " remote_ip
      config_file="/etc/netplan/pdtun$i.yaml"
      net_file="/etc/systemd/network/pdtun$i.network"
      cat <<EOF > "$config_file"
network:
  version: 2
  tunnels:
    tunel0$i:
      mode: sit
      local: $ipv4_address
      remote: $remote_ip
      addresses:
        - 2a0$number:4f8:1c1b:219b:b1::2/64
      mtu: 1500
EOF
      cat <<EOF > "$net_file"
[Network]
Address=2a0$number:4f8:1c1b:219b:b1::2/64
Gateway=2a0$number:4f8:1c1b:219b:b1::1
EOF
   number += 2
   done
elif [ "$choices" -eq 1 ]; then
   ipv4_address=$(curl -s https://api.ipify.org)
   echo "Kharej 1 IPv4 : $ipv4_address"
   read -p "enter Iran Ip : " remote_ip
   config_file="/etc/netplan/pdtun1.yaml"
   net_file="/etc/systemd/network/pdtun1.network"
   cat <<EOF > "$config_file"
network:
  version: 2
  tunnels:
    tunel01:
      mode: sit
      local: $ipv4_address
      remote: $remote_ip
      addresses:
        - 2a04:4f8:1c1b:219b:b1::1/64
      mtu: 1500
EOF
   cat <<EOF > "$net_file"
[Network]
Address=2a04:4f8:1c1b:219b:b1::1/64
Gateway=2a04:4f8:1c1b:219b:b1::2
EOF

elif [ "$choices" -eq 2 ]; then
   ipv4_address=$(curl -s https://api.ipify.org)
   echo "Kharej 2 IPv4 : $ipv4_address"
   read -p "enter Iran Ip : " remote_ip
   config_file="/etc/netplan/pdtun2.yaml"
   net_file="/etc/systemd/network/pdtun2.network"
   cat <<EOF > "$config_file"
network:
  version: 2
  tunnels:
    tunel02:
      mode: sit
      local: $ipv4_address
      remote: $remote_ip
      addresses:
        - 2a06:4f8:1c1b:219b:b1::1/64
      mtu: 1500
EOF
   cat <<EOF > "$net_file"
[Network]
Address=2a06:4f8:1c1b:219b:b1::1/64
Gateway=2a06:4f8:1c1b:219b:b1::2
EOF

else
   echo "Option not implemented."
   exit 1
fi

netplan apply
sleep 0.5
systemctl restart systemd-networkd
