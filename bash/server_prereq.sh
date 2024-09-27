#!/bin/bash

# Get the current directory
SCRIPT_DIR="$(pwd)"

# SSH into the remote server and execute commands on the remote host
ssh -p 2222 <username>@<ip> << 'EOF'

# Create a new user 'ubuntu' with password 'ubuntu'
useradd -m -s /bin/bash ubuntu
echo "ubuntu:ubuntu" | chpasswd

# Grant sudo privileges to 'ubuntu' user by editing the sudoers file
echo "ubuntu ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
echo "ubuntu    ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# Change lines in sshd_config
sudo sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
sudo sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config

# Ensure other settings in sshd_config remain untouched; if not present, add the required entries
sudo grep -q "^PermitRootLogin" /etc/ssh/sshd_config || echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config
sudo grep -q "^PubkeyAuthentication" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
sudo grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

# Restart SSH service to apply changes
sudo systemctl restart sshd

# Copy the root's SSH authorized keys to ubuntu's authorized_keys
sudo mkdir -p /home/ubuntu/.ssh
sudo cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys

EOF
