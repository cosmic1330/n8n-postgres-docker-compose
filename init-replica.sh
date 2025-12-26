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
    
    echo "Dropping existing replication slot 'replica_slot_1' if it exists..."
    # 使用 replication protocol 連線並刪除 slot (如果存在)
    # 忽略錯誤 (|| true)，因為如果 slot 不存在會報錯，但我們不希望因此中斷
    psql -d "host=$PRIMARY_IP port=5432 user=${REPLICA_DB_USER} sslmode=require replication=true" \
         -c "DROP_REPLICATION_SLOT replica_slot_1" || true

    pg_basebackup \
      -d "host=$PRIMARY_IP port=5432 user=${REPLICA_DB_USER} sslmode=require" \
      -D "$PGDATA" \
      -v -P -R \
      -C -S replica_slot_1 \
      --wal-method=stream
else
    echo "Replica data directory not empty, skipping basebackup"
fi

exec postgres
