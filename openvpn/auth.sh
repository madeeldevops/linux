#!/bin/bash

# Log file path
LOG_FILE="/var/log/openvpn/auth.log"

# Log the date and time of the authentication attempt
echo "Authentication attempt: $(date)" >> "$LOG_FILE"

# Log the username and password being authenticated
echo "Authenticating username: $username, password: $password" >> "$LOG_FILE"

# Use grep to check if the username and password match in pass.txt
VALID=$(grep -E "^$username\s+$password$" /etc/openvpn/server/pass.txt)
if [ "$VALID" != "" ]; then
  # Authentication successful
  echo "Authentication successful" >> "$LOG_FILE"
  exit 0  # Exit code 0 indicates success
else
  # Authentication failed
  echo "Authentication failed" >> "$LOG_FILE"
  exit 1  # Exit code 1 indicates failure
fi