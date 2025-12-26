-- =====================================================
-- 1️⃣ 建立資料庫（如果不存在）
-- =====================================================

DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'n8n') THEN
      PERFORM dblink_exec('dbname=postgres', 'CREATE DATABASE n8n OWNER n8n_user');
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'app') THEN
      PERFORM dblink_exec('dbname=postgres', 'CREATE DATABASE app OWNER app_writer');
   END IF;
END
$$;

-- =====================================================
-- 2️⃣ 建立角色（全域，只做一次）
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'n8n_user') THEN
    CREATE ROLE n8n_user LOGIN PASSWORD 'n8n_password';
    ALTER ROLE n8n_user CONNECTION LIMIT 5;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_writer') THEN
    CREATE ROLE app_writer LOGIN PASSWORD 'app_writer_password';
    ALTER ROLE app_writer CONNECTION LIMIT 20;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_reader') THEN
    CREATE ROLE app_reader LOGIN PASSWORD 'app_reader_password';
    ALTER ROLE app_reader CONNECTION LIMIT 20;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'replicator') THEN
    CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'replicator_pass';
  END IF;
END
$$;

-- =====================================================
-- 3️⃣ n8n DB 權限
-- =====================================================

\connect n8n;

GRANT CONNECT ON DATABASE n8n TO n8n_user;
GRANT USAGE, CREATE ON SCHEMA public TO n8n_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO n8n_user;

-- =====================================================
-- 4️⃣ app DB 權限
-- =====================================================

\connect app;

GRANT CONNECT ON DATABASE app TO app_writer, app_reader;
GRANT USAGE ON SCHEMA public TO app_writer, app_reader;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO app_writer;

GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO app_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES TO app_writer;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT
ON TABLES TO app_reader;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- =====================================================
-- 5️⃣ 安全性強化
-- =====================================================

-- 撤銷 PUBLIC 角色在所有資料庫上的預設連線權限
-- 確保只有透過 GRANT 指定的角色才能連線
REVOKE CONNECT ON DATABASE n8n FROM PUBLIC;
REVOKE CONNECT ON DATABASE app FROM PUBLIC;
REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;

\connect postgres;
-- 不特別給 app / n8n 權限，root 管理即可
-- root 權限已在 pg_hba.conf 限制為本地存取
