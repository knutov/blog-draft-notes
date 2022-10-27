# setup Prometheus with basic auth

```bash

d=$(mktemp -d) && cd $d

curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -

# jq way that will work in case of change formatting
# curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r '.assets[].browser_download_url | select(endswith(".linux-amd64.tar.gz"))' | wget -qi -

tar xvf prometheus*.tar.gz
cd prometheus*/

mv prometheus promtool /usr/local/bin/
mv prometheus.yml /etc/prometheus/prometheus.yml
mv consoles/ console_libraries/ /etc/prometheus/

rm -fr ${d:?}

# Create data folder. Config folders are already created during installation of node_exporter
mkdir /var/lib/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus/

# generate password file
pass=my-sec-pass # replace it with your own

PASS=$(bcrypt-tool hash ${pass:?})
echo $PASS

mkdir -p /etc/prometheus/

cat << EOF > /etc/prometheus/prometheus.web.yml
basic_auth_users:
  admin: $PASS
EOF

chmod 700 /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus

cat << EOF > /etc/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label \`job=<job_name>\` to any timeseries scraped from this config.
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
    basic_auth:
      username: 'admin'
      password: '$pass'
  - job_name: node
    static_configs:
    - targets: ['localhost:9100']
    #file_sd_configs:
    #  - files:
    #    - /etc/prometheus/lxd-nodes.yml
    basic_auth:
      username: 'prom'
      password: '$pass'
    relabel_configs:
      - source_labels: [instance]
        target_label: __tmp_instance
        regex: '(.+)'
        replacement: '\${1};'
      - source_labels: [__tmp_instance, __address__]
        separator: ''
        target_label: instance
        regex: '([^:;]+)((:[0-9]+)?|;(.*))'
        replacement: '\${1}'
  - job_name: dmesg
    static_configs:
    - targets: ['localhost:9101']
  - job_name: mysql # To get metrics about the mysql exporter’s targets
    params:
      # auth_module: client.servers
    static_configs:
    - targets:
      # All mysql hostnames to monitor.
      - localhost:9104
EOF

cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=100
StartLimitBurst=5


[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=:9090 \
  --web.config.file=/etc/prometheus/prometheus.web.yml \
  --web.enable-admin-api \
  --web.enable-lifecycle

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl restart prometheus
```

## Check status

```bash
systemctl status prometheus.service
```

## Reload config via api

```bash
curl -X POST http://localhost:9090/-/reload -u "admin:my-sec-pass" # replace your password
```

## Details about double relable

https://stackoverflow.com/questions/49896956/relabel-instance-to-hostname-in-prometheus