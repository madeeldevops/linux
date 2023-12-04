You have to create two server and two client with different bandwidth. The wg0 will have bandwidth control with the help of limit-bw.sh script

You have to create keys for both server and clients.
You can create keys with
    wg genkey | tee privatekey | wg pubkey > publickey

You can make your network online by 
    wg-quick up wg1
Do remember to change the port for different networks

For lxc use proxy
lxc config device add wireguard wg41195 proxy listen=udp:server ip:41195 connect=udp:lxc ip:41195

You can create a QR code for the peer by
    qrencode -t ansiutf8 < android.conf
