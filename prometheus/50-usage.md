# Usage notes and examples

TODO - https://stackoverflow.com/questions/59767178/mysqld-exporter-data-source-name-in-mysqld-exporter-service

- <https://prometheus.io/webtools/alerting/routing-tree-editor/>

Exporters:

- <https://prometheus.io/docs/instrumenting/exporters/>
- <https://github.com/prometheus/prometheus/wiki/Default-port-allocations>



## Combine two query on Prometheus graphs

```promql
label_replace(rate(node_network_receive_bytes_total{device=~"eno1|eno0|eth1"}[1m]), "bytes", "in", "job", ".*")
or
label_replace(rate(node_network_transmit_bytes_total{device=~"eno1|eno0|eth1"}[1m]), "bytes", "out", "job", ".*")
```

or in bits (`bytes*8`)

```promql
label_replace(rate(node_network_receive_bytes_total{device=~"eno1|eno0|eth1"}[1m])*8, "bits", "in", "job", ".*")
or
label_replace(rate(node_network_transmit_bytes_total{device=~"eno1|eno0|eth1"}[1m])*8, "bits", "out", "job", ".*")
```

## Memory usage

```promql
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
```

## Find LXD containers with heavy websites

```promql
rate(node_zfs_zpool_dataset_writes{dataset=~".+containers.+"}[1m]) > 500
```

```promql
label_replace(rate(node_zfs_zpool_dataset_writes{dataset=~".+containers.+"}[1m]) > 500, "ct", "$1", "dataset", ".*containers/(.+)$")
```

## dmesg exporter

```bash
go install github.com/cirocosta/dmesg_exporter@latest
/root/go/bin/dmesg_exporter start --address="localhost:9101"  --path='/metrics'
```

## Misc

```bash
curl -X POST http://localhost:9090/-/reload
curl -X POST http://localhost:9090/-/reload -u "admin:pass"

./promtool check web-config web.yml

curl -X POST http://localhost:9090/api/v1/query -u "admin:***" -d 'query=node_network_transmit_bytes_total{device="eno1"}' | jq .
```

## Delete unwanded instance

`-g` option switches off the "URL globbing parser". When you set this option, you can specify URLs that contain the letters `{}[]` without having them being interpreted by curl itself.

```bash
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={instance="some.server:1234"}'
```

+ see https://www.shellhacks.com/prometheus-delete-time-series-metrics/

## for mysqld_exporter (TODO)

```bash
DATA_SOURCE_NAME=$(cat ~/.my.cnf | grep superuser | sed 's/#\s//' | sed 's/\s//' | awk '{print $1"@unix(/var/run/mysqld/mysqld.sock)/?allowCleartextPasswords=true"}') \
./mysqld_exporter --no-collect.auto_increment.columns --collect.info_schema.processlist.processes_by_user  --collect.info_schema.processlist.processes_by_host --web.listen-address=":9104" --collect.info_schema.processlist --config.my-cnf="/root/.my.cnf"

echo $(cat ~/.my.cnf | grep superuser | sed 's/#\s//' | sed 's/\s//')'@unix(/var/run/mysqld/mysqld.sock)/?allowCleartextPasswords=true'
```

## Alerts

See

- https://github.com/prometheus/alertmanager/issues/1187
- https://github.com/prometheus/alertmanager

```bash
# cat ~/.config/amtool/config.yml
alertmanager.url: http://localhost:9093
author: Nick # change it!
require-comment: false
output: simple
http.config.file: /root/.config/amtool/config.web.yml

~# cat ~/.config/amtool/config.web.yml
basic_auth:
  username: admin
  password: ***
```

```bash
amtool silence add alertname=HostContextSwitching
```