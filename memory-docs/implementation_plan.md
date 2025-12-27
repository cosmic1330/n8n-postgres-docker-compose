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
