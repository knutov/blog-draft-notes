# Grafana

```bash
wget https://dl.grafana.com/oss/release/grafana_9.2.2_amd64.deb
sudo dpkg -i grafana_9.2.2_amd64.deb


sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl start grafana-server
```

Now we should go to http://your-server:3000 and change password. Default is `admin:admin`.

Then we can import dashboard "Node exporter full" by number `1860` or `11074`. Adjust it to your needs.
