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
    read -p "whats your domain:" domain
    cat > config.json << EOF
{
    "name": "tls_port_to_port_grpc_iran",
    "nodes": [
        {
            "name": "input",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": [443,65535],
                "nodelay": true
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
                "host": "$domain",
                "port": 443,
                "path": "/",
                "content-type": "application/grpc"
            },
            "next": "sslclient"
        },
        {
            "name": "sslclient",
            "type": "OpenSSLClient",
            "settings": {
                "sni": "mydomain.ir",
                "verify": true,
                "alpn": "h2"
            },
            "next": "output"
        },
        {
            "name": "output",
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
elif [ "$choice" -eq 2 ]; then
    echo "You chose Kharej."
    read -p "enter Iran Ip: " ip_remote
    cat > config.json << EOF
{
    "name": "tls_port_to_port_grpc_kharej",
    "nodes": [
        {
            "name": "input",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": 443,
                "nodelay": true
            },
            "next": "sslserver"
        },
        {
            "name": "sslserver",
            "type": "OpenSSLServer",
            "settings": {
                "cert-file": "fullchain.pem",
                "key-file": "privkey.pem",
                "alpns": [
                    {
                        "value": "h2",
                        "next": "node->next"
                    },
                    {
                        "value": "http/1.1",
                        "next": "node->next"
                    }
                ]
            },
            "next": "pbserver"
        },
        {
            "name": "pbserver",
            "type": "ProtoBufServer",
            "settings": {},
            "next": "h2server"
        },
        {
            "name": "h2server",
            "type": "Http2Server",
            "settings": {},
            "next": "output"
        },
        {
            "name": "output",
            "type": "Connector",
            "settings": {
                "nodelay": true,
                "address": "127.0.0.1",
                "port": 443
            }
        }
    ]
}  
EOF

read -p "Enter the domain name: " DOMAIN
openssl req -newkey rsa:2048 -nodes -keyout "privkey.pem" -x509 -days 365 -out "fullchain.pem" -subj "/CN=$DOMAIN"
echo "SSL certificate and key have been saved in the current directory as fullchain.pem and privkey.pem"

elif [ "$choice" -eq 3 ]; then
    echo "Exiting."
    exit 0
else
    echo "Invalid choice. Please try again."
fi
