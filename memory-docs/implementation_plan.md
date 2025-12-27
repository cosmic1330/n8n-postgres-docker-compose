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
