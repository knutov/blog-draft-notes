# CrowdSec

## Install on Ubuntu

```bash
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash

apt install -y crowdsec crowdsec-firewall-bouncer-iptables

# to optimize ip ranges
cscli scenarios install crowdsecurity/ban-defcon-drop_range
systemctl reload crowdsec

apt install bash-completion
mkdir -p /etc/bash_completion.d/
cscli completion bash | sudo tee /etc/bash_completion.d/cscli
# relogin afrer this to apply bash autocompletion

# initial training
crowdsec -dsn file:///var/log/auth.log -type syslog  -no-api
```

## Install on Centos 7

```bash
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.rpm.sh | sudo bash
yum install -y crowdsec crowdsec-firewall-bouncer-iptables
cscli scenarios install crowdsecurity/ban-defcon-drop_range
systemctl reload crowdsec

yum install -y bash-completion bash-completion-extras
mkdir -p /etc/bash_completion.d/
cscli completion bash | sudo tee /etc/bash_completion.d/cscli

locate bash_completion.sh
source /etc/profile.d/bash_completion.sh
```
## Example commands:

```bash
cscli alerts list
cscli decisions list
cscli config show
cscli collections list
cscli console status
cscli bouncers list
cscli metrics

# list of logs to follow
cat /etc/crowdsec/acquis.yaml

ipset list crowdsec-blacklists

# train by log
crowdsec -dsn file:///var/log/auth.log -type syslog  -no-api

# Check
cscli decisions list --all | grep IP
# or by grepping /var/log/crowdsec.log

# Ban
cscli decisions add --ip 1.2.3.4
cscli decisions add --range 1.2.3.0/24
cscli decisions add --ip 1.2.3.4 --duration 24h --type captcha
cscli decisions add --scope username --value foobar
```

## Protect Dovecot from password bruteforce and load to MySQL backend

```bash
cscli collections install crowdsecurity/dovecot

# I need this fix to parse log if I use sql backend for auth.
# Use https://grokdebug.herokuapp.com/ to debug when writing additional filters

cat << 'EOF' > /etc/crowdsec/hub/parsers/s01-parse/crowdsecurity/dovecot-logs.yaml
#contribution by @ltsich
onsuccess: next_stage
debug: false
filter: "evt.Parsed.program == 'dovecot'"
name: crowdsecurity/dovecot-logs
description: "Parse dovecot logs"
nodes:
  - grok:
      pattern: "%{WORD:protocol}-login: %{DATA:dovecot_login_message}: user=<%{DATA:dovecot_user}>.*, rip=%{IP:dovecot_remote_ip}, lip=%{IP:dovecot_local_ip}"
      apply_on: message
  - grok:
      pattern: "auth-worker\\(%{INT}\\): pam\\(%{DATA:dovecot_user},%{IP:dovecot_remote_ip},?%{DATA}\\): (%{DATA}: )?%{DATA:dovecot_login_message}$"
      apply_on: message
  - grok:
      pattern: "auth-worker\\(%{INT}\\): conn unix:auth-worker \\(pid=%{INT},uid=%{INT}\\): auth-worker<%{INT}>: pam\\(%{DATA:dovecot_user},%{IP:dovecot_remote_ip},?%{DATA}\\): (%{DATA}: )?%{DATA:dovecot_login_message}$"
      apply_on: message
  - grok:
      pattern: "auth-worker\\(%{INT}\\): sql\\(%{DATA:dovecot_user},%{IP:dovecot_remote_ip},?%{DATA}\\): (%{DATA}: )?%{DATA:dovecot_login_message}$"
      apply_on: message
statics:
    - meta: log_type
      value: dovecot_logs
    - meta: source_ip
      expression: "evt.Parsed.dovecot_remote_ip"
    - meta: dovecot_login_result
      expression: "any(['Authentication failure', 'password mismatch', 'Password mismatch', 'auth failed', 'unknown user'], {evt.Parsed.dovecot_login_message contains #}) ? 'auth_failed' : ''"
EOF

# adjust timers, optional.
# Sometimes defauls are better here, "capacity: 1" can be not good for some cases
cat << 'EOF' > /etc/crowdsec/hub/scenarios/crowdsecurity/dovecot-spam.yaml
#contribution by @ltsich
type: leaky
name: crowdsecurity/dovecot-spam
description: "detect errors on dovecot"
debug: false
filter: "evt.Meta.log_type == 'dovecot_logs' && evt.Meta.dovecot_login_result == 'auth_failed'"
groupby: evt.Meta.source_ip
capacity: 1
leakspeed: "360s"
blackhole: 5m
labels:
 type: scan
 remediation: true
EOF

# add dovecot log to follow
cat << 'EOF' >> /etc/crowdsec/acquis.yaml
filenames:
  - /var/log/dovecot.log
labels:
  type: syslog
---
EOF

service crowdsec restart

# train with current log
crowdsec -dsn file:///var/log/dovecot.log -type dovecot -no-api
```

## TODO

https://powerdns.github.io/weakforced/

https://github.com/PowerDNS/weakforced

https://powerdns.github.io/weakforced/docker/wforce_docker.html

https://discord.com/channels/921520481163673640/922593826986672178/1034126971262746704

https://discourse.crowdsec.net/t/no-decisions-for-the-scope/358

https://github.com/crowdsecurity/crowdsec/issues/1152