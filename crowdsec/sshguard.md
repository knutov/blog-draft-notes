# sshguard

Important note: `sshguard` requires manual configuration to support `ipset` and do not have any prepared wellknown list of attackers. It's better to use CrowdSec instead.

`ipset` is important, because `iptables` can be very slow when blocking ip one by one via separate rules.

## Why to use?

```bash
cat /var/log/auth.log | grep 'Connection closed by invalid' | head
cat /var/log/auth.log | grep 'Connection closed by invalid' | wc -l

# list of attackers ip
cat /var/log/auth.log | grep 'Connection closed by invalid' | awk '{print $12}' | sort | uniq  | grep -v port
```

## Installation

```bash
apt install sshguard

# adjust /etc/sshguard/sshguard.conf
```

## remove sshguard

```bash
apt remove sshguard -y
iptables -D sshguard
iptables -X sshguard
iptables -L
```