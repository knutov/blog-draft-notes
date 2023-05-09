# setup Prometheus with basic auth

```bash
# optional for ZFS
zfs create tank/alertmanager
zfs set mountpoint=/var/lib/alertmanager tank/alertmanager

# install Alertmanager
d=$(mktemp -d) && cd $d

curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest | jq -r '.assets[].browser_download_url | select(endswith(".linux-amd64.tar.gz"))' | wget -qi -

tar xvf alertmanager-*.tar.gz
cd alertmanager-*/

mv alertmanager amtool /usr/local/bin/
mv alertmanager.yml /etc/prometheus/alertmanager.yml

rm -fr ${d:?}


# Create data folder.

mkdir /var/lib/alertmanager
sudo chown -R prometheus:prometheus /var/lib/alertmanager/


# generate password file
# pass=my-sec-pass # replace it with your own

PASS=$(bcrypt-tool hash ${pass:?})
echo $PASS

mkdir -p /etc/prometheus/

cat << EOF > /etc/prometheus/web.alertmanager.yml
basic_auth_users:
  admin: $PASS
EOF

chmod 700 /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus

cat << EOF > /etc/prometheus/alertmanager.yml
...
EOF

cat << EOF > /etc/systemd/system/alertmanager.service
[Unit]
Description=alertmanager
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=100
StartLimitBurst=5

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/prometheus/alertmanager.yml \
  --storage.path=/var/lib/alertmanager/ \
  --web.listen-address="0.0.0.0:9093" \
  --web.config.file=/etc/prometheus/web.alertmanager.yml \
  --cluster.advertise-address=0.0.0.0:9093

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable alertmanager --now
systemctl status alertmanager
# systemctl restart alertmanager
```

## Check status

```bash
amtool check-config /etc/prometheus/alertmanager.yml
systemctl status alertmanager.service
```

## Test alert

```bash
curl -H 'Content-Type: application/json' -d '[{"labels":{"alertname":"myalert"}}]' http://localhost:9093/api/v1/alerts
curl -H 'Content-Type: application/json' -d '[{"labels":{"alertname":"myalert"}, "status": "resolved" }]' http://localhost:9093/api/v1/alerts
```
