#!/bin/bash

set -e

ip link set lo up
ip link set eth0 up
ip addr add 120.0.32.68/28 dev eth0
ip route add default via 120.0.32.65

mysqld_safe --bind-address=0.0.0.0 --skip-networking=0 > /var/log/mysqld.log 2>&1 &

# Attente du démarrage
until mariadb -uroot -e "SELECT 1" >/dev/null 2>&1; do
  sleep 1
done

mariadb -uroot <<'EOF'
CREATE DATABASE IF NOT EXISTS radius;
CREATE USER IF NOT EXISTS 'radius'@'%' IDENTIFIED BY 'radiuspass';
GRANT ALL PRIVILEGES ON radius.* TO 'radius'@'%';
FLUSH PRIVILEGES;
EOF

if [ -f /etc/radius-schema.sql ]; then
  mariadb -uroot radius < /etc/radius-schema.sql
fi

echo "DB up on 120.0.32.68:3306 (db radius, user radius/radiuspass)"
