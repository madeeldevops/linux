#!/bin/bash

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Define the inventory file path
INVENTORY="inventory"

# Log file to capture output
LOGFILE="ansible_playbooks.log"
exec > >(tee -i "$LOGFILE") 2>&1

# Function to run a playbook
run_playbook() {
  PLAYBOOK="$1"
  echo "-------------------------------------------------"
  echo "Running $PLAYBOOK..."
  echo "-------------------------------------------------"
  ansible-playbook -i "$INVENTORY" "$PLAYBOOK"
}

# Run the create-django-app.yml playbook
run_playbook "create-django-app.yml"

# Run the install-nginx.yml playbook
run_playbook "install-nginx.yml"

# Run the create-service.yml playbook
run_playbook "create-service.yml"

echo "All playbooks executed successfully."
