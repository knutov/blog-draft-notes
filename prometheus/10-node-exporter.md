# Setup node_exporter with basic auth

```bash

# Download and install latest binary

d=$(mktemp -d) && cd $d

curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -

# curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | jq -r '.assets[].browser_download_url | select(endswith(".linux-amd64.tar.gz"))' | wget -qi -

tar xzf node_exporter-*.tar.gz
cd node_exporter-*/

cp node_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/node_exporter

rm -fr ${d:?}

# Generate file for basic auth for node_exporter
pass=my-sec-password # replace it with your own

PASS=$(bcrypt-tool hash ${pass:?})
echo $PASS

cat << EOF > /etc/prometheus/node_exporter.web-config.yml
basic_auth_users:
  prom: $PASS
EOF

chmod 700 /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus

# Generate systemd service

cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config=/etc/prometheus/node_exporter.web-config.yml --web.listen-address=":9100"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
```

## Check status

```bash
systemctl status node_exporter.service
```

## Debug in case we change something and it is not working

```bash
# Check if it runs
/usr/local/bin/node_exporter --web.config=/etc/prometheus/node_exporter.web-config.yml --web.listen-address=":9100"

# and check auth on the same server (replace password to actual)
curl -v -u "prom:pass" http://localhost:9100/

# check file configs are readable

runuser -u prometheus -- ls -l /etc/prometheus/node_exporter.web-config.yml
runuser -u prometheus -- ls -l /etc/prometheus
```