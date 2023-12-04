Check if openvpn.service is running and the port, get the client.ovpn file and add this in your phone app.
systemctl restart openvpn-server@server.service
tail -f /var/log/syslog | grep -E "openvpn | openvpn-server@server.service"
server.conf 
client.ovpn
auth.sh
-rwxr-xr-x 1 nobody nogroup  718 Dec  1 10:27 auth.sh*
pass.txt
Don't for get to create  log file with permission chmod o+w auth.log
