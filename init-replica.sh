#!/bin/bash
set -e

PRIMARY_IP=172.25.0.5

echo "Waiting for primary..."
until pg_isready -h "$PRIMARY_IP" -p 5432 -U "${REPLICA_DB_USER}"; do
  sleep 2
done

# 如果我們是以 root 運行（例如某些環境下的 entrypoint），需要確保 postgres 擁有目錄
# 但在 docker-compose 中我們設定了 user: postgres，所以這裡主要是確保權限正確
if [ "$(id -u)" = "0" ]; then
    chown -R postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"
fi

# 只在資料目錄真的空時才做 basebackup
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Initializing replica from primary..."
    export PGPASSWORD="${REPLICA_DB_PASSWORD}"
    
    # 確保目錄存在且權限正確（如果不是空目錄但沒 PG_VERSION，可能需要清理，但這裡採保守做法）
    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA"

    echo "Dropping existing replication slot 'replica_slot_1' if it exists..."
    psql -d "host=$PRIMARY_IP port=5432 user=${REPLICA_DB_USER} sslmode=require replication=true" \
         -c "DROP_REPLICATION_SLOT replica_slot_1" || true

    pg_basebackup \
      -d "host=$PRIMARY_IP port=5432 user=${REPLICA_DB_USER} sslmode=require" \
      -D "$PGDATA" \
      -v -P -R \
      -C -S replica_slot_1 \
      --wal-method=stream

    echo "Replica initialization completed."
else
    echo "Replica data directory not empty, jumping to start."
fi

# 最後確保權限正確，避免啟動失敗
if [ "$(id -u)" = "0" ]; then
    chown -R postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"
    echo "Starting PostgreSQL Replica as postgres user..."
    exec gosu postgres postgres \
      -c wal_level=replica \
      -c max_wal_senders=10 \
      -c max_replication_slots=10 \
      -c hot_standby=on \
      -c ssl=on \
      -c ssl_cert_file=/var/lib/postgresql/18.1/docker/server.crt \
      -c ssl_key_file=/var/lib/postgresql/18.1/docker/server.key \
      -c ssl_ca_file=/var/lib/postgresql/18.1/docker/root.crt
else
    echo "Starting PostgreSQL Replica..."
    exec postgres \
      -c wal_level=replica \
      -c max_wal_senders=10 \
      -c max_replication_slots=10 \
      -c hot_standby=on \
      -c ssl=on \
      -c ssl_cert_file=/var/lib/postgresql/18.1/docker/server.crt \
      -c ssl_key_file=/var/lib/postgresql/18.1/docker/server.key \
      -c ssl_ca_file=/var/lib/postgresql/18.1/docker/root.crt
fi
