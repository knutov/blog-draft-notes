# Limit systemd-journal disk usage

Short version:

```bash
echo 'SystemMaxUse=50M' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
```

Long version to be sure the used size is no more than desired:

```bash
journalctl --disk-usage
echo 'SystemMaxUse=50M' >> /etc/systemd/journald.conf
systemctl restart systemd-journald
journalctl --rotate # do not exist in systemd 219 (Centos 7)
journalctl --vacuum-time=2d # works with systemd 219
journalctl --disk-usage
fstrim -va
```

## Change setting in separate file
`/etc/systemd/journald.conf.d/*.conf` overrides settings from the file `/etc/systemd/journald.conf`. You can write config here, example format:

```text
[Journal]
SystemMaxUse=250M
SystemMaxFileSize=50M
```

## Useful commands:

```bash
systemctl --version
journalctl --disk-usage
journalctl --verify
journalctl --vacuum-time=2d
journalctl --vacuum-size=500M
journalctl --vacuum-time=1s
journalctl --flush
journalctl --rotate
```

See also:

- https://wiki.manjaro.org/index.php/Limit_the_size_of_.log_files_%26_the_journal
- https://selectel.ru/blog/en/2017/01/24/managing-logging-systemd/