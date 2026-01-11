# interfaces :
# eth0 : routeurParis 120.0.33.7/31
# eth1 : ReseauService 120.32.65/28


# initialisation des interfaces :
ip link set eth0 up
ip link set eth1 up

# initialisation des addresses ip
ip addr add 120.0.33.7/31 dev eth0
ip addr add 120.0.32.65/28 dev eth1

# Autoriser le routage L3 et eviter les drops en cas de chemins asymetriques.
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0

# Pare-feu simple pour protéger le réseau ServicesFAI
iptables -F
iptables -X
iptables -P FORWARD DROP

# Autoriser les flux établis
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Autoriser les sorties depuis ServicesFAI
iptables -A FORWARD -i eth1 -s 120.0.32.64/28 -j ACCEPT

# Autoriser l'accès aux services nécessaires depuis le core
iptables -A FORWARD -i eth0 -o eth1 -p icmp -d 120.0.32.64/28 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p udp -d 120.0.32.66 --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp -d 120.0.32.66 --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp -d 120.0.32.67 --dport 80 -j ACCEPT
# RADIUS uniquement depuis le PE Particulier
iptables -A FORWARD -i eth0 -o eth1 -s 120.0.33.41 -p udp -d 120.0.32.70 --dport 1812 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -s 120.0.33.41 -p udp -d 120.0.32.70 --dport 1813 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp -d 120.0.32.71 --dport 5201 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p udp -d 120.0.32.71 --dport 5201 -j ACCEPT


/usr/lib/frr/watchfrr.sh restart zebra ospfd
sleep 1
vtysh -b /etc/frr/frr.conf
