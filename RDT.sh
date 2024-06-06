#!/bin/bash

echo "Please choose Number:"
echo "1. Iran "
echo "2. Kharej "
echo "3. Uninstall"
read -p "Enter your choice: " choice
if [[ "$choice" -eq 1 || "$choice" -eq 2 ]]; then
    apt update
    sleep 0.5
    SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
    CURRENT_PORT=$(grep -E '^(#Port |Port )' "$SSHD_CONFIG_FILE")

    if [[ "$CURRENT_PORT" != "Port 22" && "$CURRENT_PORT" != "#Port 22" ]]; then
        sudo sed -i -E 's/^(#Port |Port )[0-9]+/Port 22/' "$SSHD_CONFIG_FILE"
        echo "SSH Port has been updated to Port 22."
        sudo systemctl restart sshd
        sudo service ssh restart
    fi
    sleep 0.5
    wget https://github.com/radkesvat/WaterWall/releases/download/v0.99/Waterwall-linux-64.zip
    apt install unzip -y
    unzip Waterwall-linux-64.zip
    sleep 0.5
    chmod +x Waterwall
    sleep 0.5
    rm Waterwall-linux-64.zip
    cat > core.json << EOF
{
    "log": {
        "path": "log/",
        "core": {
            "loglevel": "DEBUG",
            "file": "core.log",
            "console": true
        },
        "network": {
            "loglevel": "DEBUG",
            "file": "network.log",
            "console": true

        },
        "dns": {
            "loglevel": "SILENT",
            "file": "dns.log",
            "console": false

        }
    },
    "dns": {},
    "misc": {
        "workers": 0,
        "ram-profile": "server",
        "libs-path": "libs/"
    },
    "configs": [
        "config.json"
    ]
}
EOF
    public_ip=$(wget -qO- https://api.ipify.org)
    echo "Your Server IPv4 is: $public_ip"
fi
if [ "$choice" -eq 1 ]; then
    echo "You choice Iran."
    read -p "enter Kharej Ipv4 :" ip_remote
    read -p "Enter the SNI (default: www.speedtest.net): " input_sni
    HOSTNAME=${input_sni:-www.speedtest.net}
    cat > config.json << EOF
{
    "name": "reality_client_multiport",
    "nodes": [
        {
            "name": "users_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": [443,65535],
                "nodelay": true
            },
            "next": "header"
        },
        {
            "name": "header",
            "type": "HeaderClient",
            "settings": {
                "data": "src_context->port"
            },
            "next": "my_reality_client"
        },
        {
            "name": "my_reality_client",
            "type": "RealityClient",
            "settings": {
                "sni":"$HOSTNAME",
                "password":"passwd"
            },
            "next": "outbound_to_kharej"
        },

        {
            "name": "outbound_to_kharej",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address":"$ip_remote",
                "port":443
            }
        }
     
      
    ]
}
EOF
    sleep 1
    nohup ./Waterwall > /dev/null 2>&1 &
    echo "Iran IPv4 is: $public_ip"
    echo "Kharej IPv4 is: $ip_remote"
    echo "SNI $HOSTNAME"
    echo "Iran Setup Successfully Created "
elif [ "$choice" -eq 2 ]; then
    echo "You chose Kharej."
    read -p "Enter the SNI (default: www.speedtest.net): " input_sni
    HOSTNAME=${input_sni:-www.speedtest.net}
    cat > config.json << EOF
{
    "name": "reality_server_multiport",
    "nodes": [
        {
            "name": "main_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": 443,
                "nodelay": true
            },
            "next": "my_reality_server"
        },

        {
            "name": "my_reality_server",
            "type": "RealityServer",
            "settings": {
                "destination":"reality_dest_node",
                "password":"passwd"

            },
            "next": "header_server"
        },
        
        {
            "name": "header_server",
            "type": "HeaderServer",
            "settings": {
                "override": "dest_context->port"
            },
            "next": "final_outbound"
        },

        {
            "name": "final_outbound",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address":"127.0.0.1",
                "port":"dest_context->port"

            }
        },

        {
            "name": "reality_dest_node",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address":"$HOSTNAME",
                "port":443
            }
        }
      
    ]
}  
EOF
    sleep 1
    nohup ./Waterwall > /dev/null 2>&1 &
    echo "SNI $HOSTNAME"
    echo "Kharej Setup Successfully Created "
elif [ "$choice" -eq 3 ]; then
    rm -rf core.json
    rm -rf config.json
    rm -rf Waterwall
    rm -rf log
    pkill -f Waterwall
    echo "Removed"
else
    echo "Invalid choice. Please try again."
fi
