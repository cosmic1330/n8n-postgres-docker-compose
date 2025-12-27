#!/bin/bash
set -e

# 第三度檢查環境變數是否存在
: "${N8N_DB_USER:?Environment variable N8N_DB_USER is not set}"
: "${N8N_DB_PASSWORD:?Environment variable N8N_DB_PASSWORD is not set}"
: "${N8N_DB_NAME:?Environment variable N8N_DB_NAME is not set}"
: "${APP_WRITE_DB_USER:?Environment variable APP_WRITE_DB_USER is not set}"
: "${APP_WRITE_DB_PASSWORD:?Environment variable APP_WRITE_DB_PASSWORD is not set}"
: "${APP_WRITE_DB_NAME:?Environment variable APP_WRITE_DB_NAME is not set}"
: "${APP_READ_DB_USER:?Environment variable APP_READ_DB_USER is not set}"
: "${APP_READ_DB_PASSWORD:?Environment variable APP_READ_DB_PASSWORD is not set}"
: "${REPLICA_DB_USER:?Environment variable REPLICA_DB_USER is not set}"
: "${REPLICA_DB_PASSWORD:?Environment variable REPLICA_DB_PASSWORD is not set}"

echo "Starting Database Initialization with environment variables..."

# 1. 建立角色
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$$
    BEGIN
      -- n8n_user
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$N8N_DB_USER') THEN
        CREATE ROLE $N8N_DB_USER LOGIN PASSWORD '$N8N_DB_PASSWORD';
        ALTER ROLE $N8N_DB_USER CONNECTION LIMIT 5;
      END IF;

      -- app_writer
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$APP_WRITE_DB_USER') THEN
        CREATE ROLE $APP_WRITE_DB_USER LOGIN PASSWORD '$APP_WRITE_DB_PASSWORD';
        ALTER ROLE $APP_WRITE_DB_USER CONNECTION LIMIT 20;
      END IF;

      -- app_reader
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$APP_READ_DB_USER') THEN
        CREATE ROLE $APP_READ_DB_USER LOGIN PASSWORD '$APP_READ_DB_PASSWORD';
        ALTER ROLE $APP_READ_DB_USER CONNECTION LIMIT 20;
      END IF;
      
      -- replicator
      IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$REPLICA_DB_USER') THEN
        CREATE ROLE $REPLICA_DB_USER LOGIN REPLICATION PASSWORD '$REPLICA_DB_PASSWORD';
      END IF;
    END
    \$$;
EOSQL

# 2. 建立資料庫
# 檢查 n8n 資料庫
database_exists=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname = '$N8N_DB_NAME'")
if [ "$database_exists" != "1" ]; then
    echo "Creating database $N8N_DB_NAME owned by $N8N_DB_USER..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE $N8N_DB_NAME OWNER $N8N_DB_USER"
fi

# 檢查 app 資料庫
database_exists=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname = '$APP_WRITE_DB_NAME'")
if [ "$database_exists" != "1" ]; then
    echo "Creating database $APP_WRITE_DB_NAME owned by $APP_WRITE_DB_USER..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE $APP_WRITE_DB_NAME OWNER $APP_WRITE_DB_USER"
fi

# 3. 設定 n8n 權限
echo "Configuring permissions for $N8N_DB_NAME..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$N8N_DB_NAME" <<-EOSQL
    GRANT CONNECT ON DATABASE $N8N_DB_NAME TO $N8N_DB_USER;
    GRANT USAGE, CREATE ON SCHEMA public TO $N8N_DB_USER;
    ALTER DEFAULT PRIVILEGES FOR ROLE $N8N_DB_USER IN SCHEMA public GRANT ALL ON TABLES TO $N8N_DB_USER;
    REVOKE CONNECT ON DATABASE $N8N_DB_NAME FROM PUBLIC;
EOSQL

# 4. 設定 app 權限
echo "Configuring permissions for $APP_WRITE_DB_NAME..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$APP_WRITE_DB_NAME" <<-EOSQL
    GRANT CONNECT ON DATABASE $APP_WRITE_DB_NAME TO $APP_WRITE_DB_USER, $APP_READ_DB_USER;
    GRANT USAGE ON SCHEMA public TO $APP_WRITE_DB_USER, $APP_READ_DB_USER;
    
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $APP_WRITE_DB_USER;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $APP_READ_DB_USER;
    
    ALTER DEFAULT PRIVILEGES FOR ROLE $APP_WRITE_DB_USER IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $APP_WRITE_DB_USER;
    ALTER DEFAULT PRIVILEGES FOR ROLE $APP_WRITE_DB_USER IN SCHEMA public GRANT SELECT ON TABLES TO $APP_READ_DB_USER;
    
    REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    REVOKE CONNECT ON DATABASE $APP_WRITE_DB_NAME FROM PUBLIC;
EOSQL

# 5. 最終安全性強化
echo "Finalizing security..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;
EOSQL

# 6. 配置 pg_hba.conf (徹底取代預設內容以確保安全)
echo "Overwriting pg_hba.conf with custom security rules..."
cat > "$PGDATA/pg_hba.conf" <<EOF
# 1. 允許本地 Unix Socket 連線 (如 docker exec)
local   all             all                                     trust

# 2. 限制 Superuser (postgres root) 僅能從容器內部 (127.0.0.1) 連線
# 根據 .env 中的 DATABASE_USERNAME (對應 POSTGRES_USER)
local   all             $POSTGRES_USER                          trust
host    all             $POSTGRES_USER  127.0.0.1/32            trust
host    all             $POSTGRES_USER  ::1/128                 trust
host    all             $POSTGRES_USER  172.25.0.0/16           scram-sha-256
host    all             $POSTGRES_USER  0.0.0.0/0               reject

# 3. 限制 n8n_user 只能從內網連線到 n8n 資料庫 (Goal #13)
host    $N8N_DB_NAME    $N8N_DB_USER    172.25.0.0/16           scram-sha-256

# 4. 限制 app_writer 只能從內網連線到 app 資料庫 (Goal #13)
host    $APP_WRITE_DB_NAME $APP_WRITE_DB_USER 172.25.0.0/16     scram-sha-256

# 5. 允許 app_reader 可從任何地方登入但是需要 SSL (Goal #15)
hostssl $APP_WRITE_DB_NAME $APP_READ_DB_USER  0.0.0.0/0         scram-sha-256

# 6. 允許資料庫同步 (Replication) - 強制使用 SSL
hostssl replication     $REPLICA_DB_USER 172.25.0.0/16          scram-sha-256

# 7. 預設拒絕其他所有連線
host    all             all             0.0.0.0/0               reject
EOF

echo "Database initialization completed successfully."
