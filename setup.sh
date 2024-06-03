#!/bin/bash

echo "Please choose Number:"
echo "1. Iran "
echo "2. Kharej "
echo "3. Exit"
read -p "Enter your choice: " choice
if [[ "$choice" -eq 1 || "$choice" -eq 2 ]]; then
apt update
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
touch config.json
fi
if [ "$choice" -eq 1 ]; then
    echo "You choice Iran."
    read -p "enter Kharej Ipv4 :" ip_remote
    cat > config.json << EOF
{
    "name": "reverse_reality_server_multiport",
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
            "next": "bridge2"
        },
        {
            "name": "bridge2",
            "type": "Bridge",
            "settings": {
                "pair": "bridge1"
            }
        },
        {
            "name": "bridge1",
            "type": "Bridge",
            "settings": {
                "pair": "bridge2"
            }
        },
        {
            "name": "reverse_server",
            "type": "ReverseServer",
            "settings": {},
            "next": "bridge1"
        },
        {
            "name": "reality_server",
            "type": "RealityServer",
            "settings": {
                "destination": "reality_dest",
                "password": "123456as"
            },
            "next": "reverse_server"
        },
        {
            "name": "kharej_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": 443,
                "nodelay": true,
                "whitelist": [
                    "$ip_remote/32"
                ]
            },
            "next": "reality_server"
        },
        {
            "name": "reality_dest",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "8.8.8.8",
                "port": 443
            }
        }
    ]
}
EOF
elif [ "$choice" -eq 2 ]; then
    echo "You chose Kharej."
    read -p "enter Iran Ip: " ip_remote
    cat > config.json << EOF
{
    "name": "reverse_reality_client_multiport",
    "nodes": [
        {
            "name": "outbound_to_core",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "127.0.0.1",
                "port": "dest_context->port"
            }
        },
        {
            "name": "header",
            "type": "HeaderServer",
            "settings": {
                "override": "dest_context->port"
            },
            "next": "outbound_to_core"
        },
        {
            "name": "bridge1",
            "type": "Bridge",
            "settings": {
                "pair": "bridge2"
            },
            "next": "header"
        },
        {
            "name": "bridge2",
            "type": "Bridge",
            "settings": {
                "pair": "bridge1"
            },
            "next": "reverse_client"
        },
        {
            "name": "reverse_client",
            "type": "ReverseClient",
            "settings": {
                "minimum-unused": 16
            },
            "next": "reality_client"
        },
        {
            "name": "reality_client",
            "type": "RealityClient",
            "settings": {
                "sni": "www.speedtest.net",
                "password": "123456as"
            },
            "next": "outbound_to_iran"
        },
        {
            "name": "outbound_to_iran",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "$ip_remote",
                "port": 443
            }
        }
    ]
}    
EOF
    # Add the commands for Option 2 here
elif [ "$choice" -eq 3 ]; then
    echo "Exiting."
    exit 0
else
    echo "Invalid choice. Please try again."
fi

