#!/bin/bash
set -e

# 如果資料目錄空或者不存在 PG_VERSION 才拉 basebackup
if [ ! -f "$PGDATA/PG_VERSION" ] || [ -z "$(ls -A $PGDATA)" ]; then
    echo "Initializing replica..."
    export PGPASSWORD=replicator_pass
    pg_basebackup -h postgres -D "$PGDATA" -U replicator -v -P -R --wal-method=stream
else
    echo "Replica data directory not empty, skipping basebackup"
fi

exec postgres
