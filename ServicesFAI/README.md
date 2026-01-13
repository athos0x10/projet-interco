# Services FAI

Ce dossier déploie des services du FAI dans des conteneurs Docker reliés par des namespaces réseau :
- `DNS` : Bind9 servant la zone `services.fai`.
- `WEB` : nginx.
- `DB`  : MariaDB (accounting RADIUS).
- `LDAP` : OpenLDAP (base `dc=fai,dc=lab`).
- `RADIUS` : FreeRADIUS (auth LDAP + attributs de réponse).
- `IPERF` : iperf3 serveur de test.

Le LAN interne utilise `120.0.32.64/28`
L'hôte est relié au switch via l'interface `services<ID>_host` en `120.0.32.65` pour tests. On peut mettre un routeur à la place

Les adresses :
- DNS : `120.0.32.66` (`dns.services.fai`)  
- Web : `http://120.0.32.67` (`web.services.fai`)  
- DB  : `120.0.32.68:3306` (`sql.services.fai`, user `radius` / `radiuspass`)
- LDAP: `120.0.32.69:389` (`ldap.services.fai`)
- RADIUS: `120.0.32.70:1812/1813` (`radius.services.fai`)
- iPerf3: `120.0.32.71:5201` (`iperf.services.fai`)

## Vérifications:
- Résolution DNS : `dig @120.0.32.66 web.services.fai`
- Site web : `curl 120.0.32.67`
- iPerf3 : `iperf3 -c 120.0.32.71 -t 5`
- LDAP base DN : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "dc=fai,dc=lab" -s base`
- LDAP OUs : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "dc=fai,dc=lab" "(objectClass=organizationalUnit)"`
- LDAP compte RADIUS : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "cn=radius,ou=svc,dc=fai,dc=lab"`
- LDAP clients : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "ou=clients,dc=fai,dc=lab" "(|(uid=alice)(uid=bob))"`
- RADIUS (depuis le PE Particulier `fai_peParticulier`) :
  - Test ok : `docker exec -it fai_peParticulier radtest alice alicepass 120.0.32.70 0 peSecret123`
  - Test ko : `docker exec -it fai_peParticulier radtest alice wrongpass 120.0.32.70 0 peSecret123`
  - Debug FreeRADIUS : `docker exec -it servicesA_radius freeradius -X`
  - Dans le test ok, vérifier `Access-Accept` et les attributs `Framed-IP-Address` et `MS-Primary-DNS-Server` (fournis par LDAP).

## Limitation de bande passante par utilisateur (LDAP -> RADIUS -> accel-ppp)
- LDAP stocke les attributs :
  - `faiRateLimitDown` (kbit/s)
  - `faiRateLimitUp` (kbit/s)
- FreeRADIUS construit `Filter-Id = "<down>/<up>"`.
- accel-ppp applique le shaper via `Filter-Id`.
- Test :
  - `iperf3 -c iperf.services.fai -t 10` (depuis une box)

## PPPoE + IP/DNS via RADIUS (IPCP)
- Redémarrer RADIUS (si besoin) :
  - `docker exec -it servicesA_radius pkill freeradius`
  - `docker exec -it servicesA_radius freeradius`
- Redémarrer accel-ppp (PE Particulier) :
  - `docker exec -it fai_peParticulier pkill accel-pppd`
  - `docker exec -it fai_peParticulier accel-pppd -c /etc/accel-ppp.conf &`
- Sur une box abonnée (ex: `particulierA_box`) :
  - `docker exec -it particulierA_box bash`
  - `pkill dhclient || true`
  - `ip link set eth0 up`
  - `cat > /etc/ppp/peers/fai <<'EOF'
user "alice"
plugin rp-pppoe.so
eth0
noauth
defaultroute
persist
mtu 1492
mru 1492
usepeerdns
EOF`
  - `echo 'alice * "alicepass"' > /etc/ppp/pap-secrets`
  - `pppd call fai nodetach debug`
- Vérifier l’IP WAN + DNS :
  - `ip addr show ppp0`
  - `cat /etc/ppp/resolv.conf`
- Vérifier la connectivité (NAT toujours actif côté box) :
  - `ping -c 2 120.0.35.1`
  - `ping -c 2 120.0.32.66`
  - `curl 120.0.32.67`
- Logs utiles :
  - FreeRADIUS : `docker exec -it servicesA_radius freeradius -X`
  - PPP/accel-ppp : `docker exec -it fai_peParticulier tail -n 50 /var/log/accel-ppp/accel-ppp.log`

## Accounting RADIUS (MariaDB)
- Démarrer FreeRADIUS en debug :
  - `docker exec -it servicesA_radius pkill freeradius`
  - `docker exec -it servicesA_radius freeradius -X`
- (Re)lancer accel-ppp (PE Particulier) :
  - `docker exec -it fai_peParticulier pkill accel-pppd`
  - `docker exec -it fai_peParticulier accel-pppd -c /etc/accel-ppp.conf &`
- Établir puis couper une session PPPoE (box) :
  - `docker exec -it particulierA_box pppd call fai nodetach debug`
  - Arrêt : `pkill pppd`
- Vérifier la base :
  - `docker exec -it servicesA_db mariadb -uradius -pradiuspass -e "select username, framedipaddress, acctstarttime, acctstoptime, acctsessiontime from radacct order by radacctid desc limit 5;" radius`

## fichiers de config:
- Adapter la zone DNS dans `configs/dns/`.
- Modifier la page web dans `configs/web/index.html`.
- LDAP initialisation dans `scripts/script_ldap.sh`.
- RADIUS clients/utilisateurs dans `configs/radius/`.
- Schéma SQL dans `configs/db/radius-schema.sql`.

## LDAP DIT (vue arborescente)
```
dc=fai,dc=lab
├── ou=clients
│   ├── uid=alice
│   │   ├── objectClass: inetOrgPerson
│   │   ├── objectClass: faiSubscriber
│   │   ├── objectClass: faiSubscriberBw
│   │   ├── objectClass: faiSubscriberBwExt
│   │   ├── uid / cn / sn
│   │   ├── userPassword (SSHA)
│   │   ├── faiFramedIPAddress
│   │   ├── faiPrimaryDNS
│   │   ├── faiSecondaryDNS (optional)
│   │   ├── faiRateLimitDown
│   │   ├── faiRateLimitUp
│   │   └── faiRateLimit (ex: 20000/5000)
│   └── uid=bob
│       ├── objectClass: inetOrgPerson
│       ├── objectClass: faiSubscriber
│       ├── objectClass: faiSubscriberBw
│       ├── objectClass: faiSubscriberBwExt
│       ├── uid / cn / sn
│       ├── userPassword (SSHA)
│       ├── faiFramedIPAddress
│       ├── faiPrimaryDNS
│       ├── faiSecondaryDNS (optional)
│       ├── faiRateLimitDown
│       ├── faiRateLimitUp
│       └── faiRateLimit (ex: 10000/2000)
└── ou=svc
    └── cn=radius
        ├── objectClass: organizationalRole
        ├── objectClass: simpleSecurityObject
        ├── cn
        └── userPassword (SSHA)
```
