# Postgres dump for backup

This script is intended to use with external backup system in `before` hook to dump all databases in plain sql format.

It's good to be used with our commercial backup service https://ftpbox.net/alpha/

Saving sql dumps as text to local disk to backup them is good for small databases. Backup strategy should be different for large databases, most likely direct backup to `borg` via pipe.

```bash
#!/bin/bash

export PSQL=/usr/bin/psql

export PGDUMP=/usr/bin/pg_dump -U postgres --clean --if-exists
# may be better to use with `--create` option and correct UTF8 encodings

export BACKUP=~postgres/backup

mkdir -p ${BACKUP:?}
chown postgres:postgres ${BACKUP:?}
chmod 700 ${BACKUP:?}

# save all users
# NOTE: `bash -c` is here to interpolate variables from `export`
sudo -Eu postgres bash -c 'pg_dumpall --globals-only > ${BACKUP:?}/users.sql'

cd ~postgres && DBLIST=`sudo -E -u postgres -- ${PSQL:?} -U postgres -d postgres -q -t -c 'SELECT datname from pg_database WHERE datistemplate = false'`

for d in $DBLIST
do
	echo "db = $d";

	export d=$d

	# NOTE: `bash -c` is here to interpolate variables from `export`

	# We are not using `-Fc` here to save in plain text - it's good
	# for zfs+lz4 and borgbackup

	sudo -Eu postgres bash -c '${PGDUMP} $d > ${BACKUP:?}/$d.sql'
done
```
