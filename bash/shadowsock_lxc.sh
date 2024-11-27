#!/bin/bash
echo "Adeel"
# Exit on error
set -e

# Step 1: Launch the LXC container
CONTAINER_NAME="shadowsock"
echo "Launching LXC container with name $CONTAINER_NAME..."
lxc launch ubuntu:jammy $CONTAINER_NAME

# Wait for the container to initialize
echo "Waiting for container to start..."
sleep 10

# Step 2: Run commands inside the LXC container
echo "Running commands inside the container to set up Shadowsocks..."
lxc exec $CONTAINER_NAME -- bash -c "
  sudo apt update &&
  sudo apt install -y shadowsocks-libev &&
  sudo systemctl restart shadowsocks-libev &&
  sudo systemctl status shadowsocks-libev
"

# Step 3: Retrieve and display Shadowsocks configuration
echo "Retrieving Shadowsocks configuration..."
lxc exec $CONTAINER_NAME -- cat /etc/shadowsocks-libev/config.json

# Step 4: Add a proxy device to the LXC container
echo "Adding LXC proxy device..."
lxc config device add $CONTAINER_NAME shadowsock proxy listen=tcp:0.0.0.0:8388 connect=tcp:0.0.0.0:8388

# Step 5: Get the server's public IP address
echo "Fetching the server's public IP address..."
SERVER_PUBLIC_IP=$(curl -s ifconfig.me)
echo "Server Public IP Address: $SERVER_PUBLIC_IP"

echo "Setup complete. Shadowsocks should be running and accessible at $SERVER_PUBLIC_IP:8388."
