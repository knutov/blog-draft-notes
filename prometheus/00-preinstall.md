# Preinstall stuff

## Create user and config folder

```bash
# Create folder for all prometheus stuff
mkdir -p /etc/prometheus/

# Create user for all prometheus stuff
useradd -rs /bin/false prometheus
```

## Install tool to create bcrypt hashes

We will use go app to generate bcrypt password instead of `htpasswd` - it takes 32M on disk to install. Go from snap takes 100M but we usually need fresh version of `go` to compile modern tools (ans ).

```bash
snap install go --classic
go install github.com/shoenig/bcrypt-tool@latest
cp ~/go/bin/bcrypt-tool /usr/local/bin/
```

### Security notice

I assume you use `hidepid=2`, so nobody will see your passwords from commandline strings.

In `/etc/fstab`
```
proc  /proc       proc    defaults,hidepid=2    0    0
```

### Security notice 2

For simplicity we will use the same password in all next scripts.

### Usage of bcrypt-tool

```bash
bcrypt-tool hash my-secret-password
```

With automation for config generation:

```bash
pass=my-secret-password # replace it with your own

PASS=$(bcrypt-tool hash ${pass:?})
echo << EOF
basic_auth_users:
  admin: $PASS
EOF
```
