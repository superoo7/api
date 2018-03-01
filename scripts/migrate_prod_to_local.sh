#!/bin/bash
pkill -f steemhunt

PG_BIN_DIR=/usr/lib/postgresql/9.5/bin
PG_DBNAME=steemhunt
PG_UNAME=steemhunt

# Copy postgres backup
ssh steemhunt sudo -iu postgres <<< "$PG_BIN_DIR/pg_dump -d $PG_DBNAME | gzip > /tmp/postgres.gz"
scp steemhunt:/tmp/postgres.gz /tmp/

psql -d postgres -c "CREATE USER $PG_UNAME;"
psql -d postgres -c "DROP DATABASE $PG_DBNAME;"

psql -d postgres -c "ALTER USER $PG_UNAME CREATEDB;"
psql -d postgres -c "ALTER USER $PG_UNAME WITH SUPERUSER;"

psql -U $PG_UNAME -d postgres -c "CREATE DATABASE $PG_DBNAME;"

gunzip -c /tmp/postgres.gz | psql -U$PG_UNAME $PG_DBNAME