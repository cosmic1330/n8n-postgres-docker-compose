#!/bin/bash
set -e

PRIMARY_IP=172.25.0.5   # ← 固定 Primary IP

# 等 Primary 真正起來（避免無限 retry）
echo "Waiting for primary..."
until pg_isready -h "$PRIMARY_IP" -p 5432 -U "${REPLICA_DB_USER}"; do
  sleep 2
done

# 只在資料目錄真的空時才做 basebackup
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Initializing replica..."
    export PGPASSWORD="${REPLICA_DB_PASSWORD}"
    pg_basebackup \
      -h "$PRIMARY_IP" \
      -D "$PGDATA" \
      -U "${REPLICA_DB_USER}" \
      -v -P -R \
      -C -S replica_slot_1 \
      --wal-method=stream
else
    echo "Replica data directory not empty, skipping basebackup"
fi

exec postgres
