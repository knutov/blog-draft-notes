# Run multiple Redis on separate ports/sockets via systemd

```bash
# install fresh redis version
curl https://packages.redis.io/gpg | sudo apt-key add -
echo "deb https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
apt-get update
apt-get install redis -y

# disable default systemd unit
systemctl disable redis-server --now


# Based on https://blog.jeanbruenn.info/2021/08/21/systemd-multi-instance-redis/
# This unit template allows to start redis@instance-name.service (e.g. redis@project1).
cat <<EOF > /lib/systemd/system/redis@.service
[Unit]
Description=Multi-Instance Redis - a fast key value store
Documentation=https://redis.io/documentation man:redis-server(1)
Conflicts=redis-server.service
After=network.target
AssertPathExists=/etc/redis/redis-%i.conf

[Service]
# Service taken from default debian systemd redis-server.service
# and modified for %i usage
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/redis-%i.conf
ExecStop=/bin/kill -s TERM $MAINPID
PIDFile=/run/redis/redis-%i.pid
TimeoutStartSec=15
TimeoutStopSec=2
TimeoutStopSec=0
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=2755

UMask=007
PrivateTmp=yes
LimitNOFILE=65535
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
ReadWritePaths=-/var/lib/redis
ReadWritePaths=-/var/log/redis
ReadWritePaths=-/run/redis

NoNewPrivileges=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE
MemoryDenyWriteExecute=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# redis-server can write to its own config file when in cluster mode so we
# permit writing there by default. If you are not using this feature, it is
# recommended that you replace the following lines with "ProtectSystem=full".
ProtectSystem=true
ReadWriteDirectories=-/etc/redis

[Install]
WantedBy=multi-user.target
EOF


# creating separate config for our project
cat <<EOF > /etc/redis/redis-project1.conf

include /etc/redis/redis.conf

port 6381

pidfile /run/redis/redis-project1.pid
logfile /var/log/redis/redis-project1.log
dbfilename project1.rdb
EOF


systemctl enable redis@project1 --now

systemctl status redis@project1
```

# TODO

1. Write user systemd unit to run under different users:
	`%h` is for `$HOME` - see https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers for details.
	https://wiki.archlinux.org/title/systemd/User
	https://wiki.archlinux.org/title/systemd/User#PATH
