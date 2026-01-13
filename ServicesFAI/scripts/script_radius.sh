#!/bin/bash

set -e

ip link set lo up
ip link set eth0 up
ip addr add 120.0.32.70/28 dev eth0
ip route add default via 120.0.32.65

# Résolution DNS interne pour éviter les timeouts
printf "nameserver 120.0.32.66\noptions timeout:1 attempts:1\n" > /etc/resolv.conf

# Active le module LDAP
ln -sf /etc/freeradius/3.0/mods-available/ldap /etc/freeradius/3.0/mods-enabled/ldap

# Active le module SQL (MariaDB) pour l'accounting
ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
ln -sf /etc/freeradius/3.0/mods-available/attr_filter /etc/freeradius/3.0/mods-enabled/attr_filter

# Attente du serveur SQL
until mariadb -h 120.0.32.68 -uradius -pradiuspass -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

# Démarrage FreeRADIUS (mode normal)
freeradius

echo "RADIUS up on 120.0.32.70:1812/1813"
