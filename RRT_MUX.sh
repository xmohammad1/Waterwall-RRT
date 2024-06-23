#!/bin/bash

setup_waterwall_service() {
    cat > /etc/systemd/system/waterwall.service << EOF
[Unit]
Description=Waterwall Service
After=network.target

[Service]
ExecStart=/root/RRT/Waterwall
WorkingDirectory=/root/RRT
Restart=always
RestartSec=5
User=root
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable waterwall
    systemctl start waterwall
}

while true; do
    echo "Please choose Number:"
    echo "1) Iran "
    echo "2) Kharej "
    echo "3) Uninstall"
    echo "9) Back"

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
        mkdir /root/RRT
        cd /root/RRT
        wget https://github.com/radkesvat/WaterWall/releases/download/v1.18/Waterwall-linux-arm64.zip
        apt install unzip -y
        unzip -o Waterwall-linux-arm64.zip
        sleep 0.5
        chmod +x Waterwall
        sleep 0.5
        rm Waterwall-linux-arm64.zip
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
    fi

    if [ "$choice" -eq 1 ]; then
        public_ip=$(wget -qO- https://api.ipify.org)
        echo "Iran IPv4 is: $public_ip"
        read -p "enter Kharej Ipv4: " ip_remote
        read -p "Enter the SNI (default: sahab.ir): " input_sni
        HOSTNAME=${input_sni:-sahab.ir}
        cat > config.json << EOF
{
    "name": "reverse_reality_grpc_hd_multiport_server",
    "nodes": [
        {
            "name": "users_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": [23,65535],
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
            "name": "pbserver",
            "type": "ProtoBufServer",
            "settings": {},
            "next": "reverse_server"
        },
        {
            "name": "h2server",
            "type": "Http2Server",
            "settings": {},
            "next": "pbserver"
        },
        {
            "name": "halfs",
            "type": "HalfDuplexServer",
            "settings": {},
            "next": "h2server"
        },
        {
            "name": "reality_server",
            "type": "RealityServer",
            "settings": {
                "destination": "reality_dest",
                "password": "passwd"
            },
            "next": "halfs"
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
                "address": "$HOSTNAME",
                "port": 443
            }
        }
    ]
}
EOF
        sleep 0.5
        setup_waterwall_service
        sleep 0.5
        echo "Iran IPv4 is: $public_ip"
        echo "Kharej IPv4 is: $ip_remote"
        echo "SNI $HOSTNAME"
        echo "Iran Setup Successfully Created "
        read -p "Press Enter to continue"
    elif [ "$choice" -eq 2 ]; then
        public_ip=$(wget -qO- https://api.ipify.org)
        echo "Kharej IPv4 is: $public_ip"
        read -p "enter Iran Ip: " ip_remote
        read -p "Enter the SNI (default: sahab.ir): " input_sni
        HOSTNAME=${input_sni:-sahab.ir}
        cat > config.json << EOF
{
    "name": "reverse_reality_grpc_client_hd_multiport_client",
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
            "next": "pbclient"
        },
        {
            "name": "pbclient",
            "type": "ProtoBufClient",
            "settings": {},
            "next": "h2client"
        },
        {
            "name": "h2client",
            "type": "Http2Client",
            "settings": {
                "host": "$HOSTNAME",
                "port": 443,
                "path": "/",
                "contenttype": "application/grpc",
                "concurrency": 64
            },
            "next": "halfc"
        },
        {
            "name": "halfc",
            "type": "HalfDuplexClient",
            "next": "reality_client"
        },
        
        {
            "name": "reality_client",
            "type": "RealityClient",
            "settings": {
                "sni": "$HOSTNAME",
                "password": "passwd"
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
        sleep 0.5
        setup_waterwall_service
        sleep 0.5
        echo "Kharej IPv4 is: $public_ip"
        echo "Iran IPv4 is: $ip_remote"
        echo "SNI $HOSTNAME"
        echo "Kharej Setup Successfully Created "
        read -p "Press Enter to continue"
    elif [ "$choice" -eq 3 ]; then
        sudo systemctl stop waterwall
        sudo systemctl disable waterwall
        rm -rf /etc/systemd/system/waterwall.service
        pkill -f Waterwall
        rm -rf /root/RRT
        echo "Removed"
        read -p "Press Enter to continue"
    elif [ "$choice" -eq 9 ]; then
        echo "Going back..."
        break
    else
        echo "Invalid choice. Please try again."
    fi
done
