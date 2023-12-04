#!/bin/bash

# Limit outgoing bandwidth to 1 Mbps for the user with IP 192.168.6.2 on wg0
tc qdisc add dev wg0 root handle 1: htb default 12
tc class add dev wg0 parent 1: classid 1:1 htb rate 1mbit
tc filter add dev wg0 protocol ip parent 1:0 prio 1 u32 match ip dst 192.168.6.3 flowid 1:1

# Reverting commands
tc filter del dev wg0 protocol ip parent 1:0 prio 1 u32
tc class del dev wg0 classid 1:1
tc qdisc del dev wg0 root