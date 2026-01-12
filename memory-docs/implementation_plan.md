## [Postgres Replica 資安強化] - 2025-12-26 [SUCCESS]

### 實作內容

- 埠口曝露參數化 (`REPLICA_DATABASE_PORT`)。
- 強制 SSL 連線存取 (`pg_hba_replica.conf`)。
- 建立資安維護流程與更新架構圖。

## [資料庫帳戶與權限目標完成] - 2025-12-27 [SUCCESS]

### 實作內容

- 建立並驗證 `app_writer`, `app_reader`, `n8n_user` 角色與對應資料庫。
- 實作嚴格的 `pg_hba.conf` 存取控制（限制 root、限制寫入者僅限內網、允許讀取者 SSL 存取）。
- 修正 `init-replica.sh` 的目錄權限與 SSL 啟動參數。
- 驗證 Primary-Replica 資料同步與 `app_reader` 的唯讀權限。

## [資料庫存取策略調整] - 2025-12-27 [SUCCESS]

### 實作內容

- 修改 `init-db.sh` 授予 `app_reader` 對 `postgres` 與 `app` 資料庫的存取權限，並**明確移除所有寫入權限** (REVOKE CREATE)。
- 更新 `pg_hba.conf` 允許 `app_reader` 透過 SSL 從任何地方存取上述資料庫。
- 修正 `architecture.md` 中的檔案名稱錯誤 (`init-db.sql` -> `init-db.sh`)。
- 驗證 `postgres-replica` 服務正常運行且 `app_reader` 權限嚴格限制為唯讀。

## [SSL 憑證生成腳本修復 (X.509 v3)] - 2025-12-27 [SUCCESS]

### 實作內容

- 更新 `scripts/generate-ssl.sh` 使用 X.509 v3 擴充功能與 SAN (Subject Alternative Name)。
- 加入對 `postgres`、`localhost`、`127.0.0.1` 的支援。
- 修正伺服器金鑰權限設定為 600。
- 驗證憑證版本為 v3 (0x2) 且包含 SAN 欄位。

## [app_reader 升級為 mTLS 雙重驗證] - 2025-12-27 [SUCCESS]

### 實作內容

- 更新 `scripts/generate-ssl.sh`：
  - 生成客戶端 Root CA (使用現有 Root CA)。
  - 為 `app_reader` 生成專屬客戶端憑證 (`client.crt`, `client.key`)。
  - 修正 SAN (Subject Alternative Name) 以包含 `postgres-replica`。
- 修改 `init-db.sh` 中的 `pg_hba.conf` 規則：
  - 將 `app_reader` 的 `hostssl` 規則加入 `clientcert=verify-ca` 參數。
- 更新 `api-bridge` 服務：
  - 代碼整合 `node-postgres` 的 SSL 設定。
  - 透過 Docker Compose 掛載客戶端憑證。
- 驗證流程：確保無憑證連線、無密碼連線均會失敗，僅允許「有效憑證 + 正確密碼」。

## [SMB Volume for Backups] - 2026-01-12 [IN PROGRESS] 🛠️

> [!WARNING]
> 目前遭遇 `permission denied` 錯誤，通常是因為宿主機缺少 `cifs-utils` 或 SMB 憑證錯誤。

### 實作內容

- 在 `docker-compose.yml` 中定義名為 `smb_backup` 的具名磁碟卷，使用 `cifs` 驅動程式連接至 `//yang_nas.local/hdd`。
- 將 `n8n` 與 `postgres-backup` 服務的備份掛載點從本地目錄改為 `smb_backup`。
- 在 `.env` 與 `.env.example` 中新增 SMB 認證相關變數 (`SMB_USER`, `SMB_PASSWORD`, `SMB_DOMAIN`)。
- 更新 `architecture.md` 以反映備份基礎架構的變更。
