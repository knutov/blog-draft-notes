# Grafana

```bash
# optional for ZFS
zfs create tank/grafana
zfs set mountpoint=/var/lib/grafana tank/grafana

# install grafana from mirror repo
apt-get install -y apt-transport-https
apt-get install -y software-properties-common wget
echo "deb [trusted=yes] http://mirrors.cloud.tencent.com/grafana/apt/ stable main" | tee /etc/apt/sources.list.d/grafana.list
apt update

# install grafana
apt install grafana

/bin/systemctl daemon-reload
/bin/systemctl enable grafana-server --now
# /bin/systemctl restart grafana-server
```

Now we should go to http://your-server:3000 and change password. Default is `admin:admin`.

Then we can import dashboard "Node exporter full" by number `1860` or `11074`. Adjust it to your needs.

See also: https://grafana.com/tutorials/run-grafana-behind-a-proxy/
