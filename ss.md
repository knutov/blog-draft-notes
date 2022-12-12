# ss

`ss` is modern replace for `netstat`.

- `ss -l` to display only listening sockets.
- `-a` to display all sockets (listening + established)
- `-p` - show process using socket
- `-n` to print numeric values (22 instead of "ssh")

- `ss -o state established '( dport = :ssh or sport = :ssh )'` to print all established ssh connections
- `ss -nl | grep 3306` to print all listening mysqls

## Replacement

- `netstat -a` -> `ss -a`
- `netstat -tulp` -> `ss -tulp`
