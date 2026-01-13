sudo ip link add entreprise type veth peer name host netns entreprise_client1_RH
sudo ip a a 10.200.0.1/24 dev entreprise
sudo ip link set entreprise up
sudo ip netns exec entreprise_client1_RH ip a a 10.200.0.2/24 dev host
sudo ip netns exec entreprise_client1_RH ip link set host up
sudo ip route add default via 10.200.0.2 dev entreprise table 100
sudo ip rule add iif wlp2s0 lookup 100
sudo ip netns exec entreprise_client1_RH iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -t nat -A PREROUTING -i wlp2s0 -p udp --dport 53 -j DNAT --to-destination 192.168.49.18