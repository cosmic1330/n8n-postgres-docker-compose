# Technology Stack

## 基礎架構 (Infrastructure)

- **容器化平台**: Docker, Docker Compose
- **作業系統**: Ubuntu 22.04 LTS (推薦宿主機)
- **反向代理**: Nginx (最新版)
- **DNS**: 使用 Google DNS (8.8.8.8) 與 Cloudflare DNS (1.1.1.1) 確保連線穩定

## 資料庫與連線管理 (Database & Connection Pooling)

- **主要資料庫 (Primary)**: PostgreSQL 18
  - `wal_level`: replica
  - `max_wal_senders`: 10
  - `max_replication_slots`: 10
  - `ssl`: on (Enabled with self-signed certificates)
- **複製品資料庫 (Replica)**: PostgreSQL 18 (Hot Standby)
- **連線池管理 (PgBouncer)**:
  - `pgbouncer-n8n`: 提供給 n8n 使用，模式為 `session` (Backend SSL: require)
  - `pgbouncer-app`: 提供給一般應用程式使用，模式為 `transaction` (Backend SSL: require)

## 應用程式層 (Application Layer)

- **n8n**: 基於 `n8nio/n8n:latest` 的自定義映像檔
- **API Bridge (Secure Gateway)**:
  - 基於 Node.js 20 (Express)
  - 提供外部應用存取內部資料庫的唯一窗口
  - 整合 API Key 驗證機制
- **自動化功能擴充**:
  - `n8n-nodes-puppeteer`: 支援瀏覽器自動化操作
  - `chromium`: 內建於 Docker 映像檔中供 Puppeteer 使用
  - `cheerio`: 網頁解析工具
  - `@ch20026103/anysis`: 自定義分析工具套件

## 環境配置 (Environment Configuration)

- **安全性**:
  - 使用 `.env` 進行敏感資訊管理
  - 支援 SSL/TLS 加密 (透過 Nginx)
- **時區**: `Asia/Taipei` (GMT+8)

## 宿主機資安強化 (Host Security Hardening)

為了保護伺服器不受暴力破解與木馬攻擊，建議對 Ubuntu 宿主機執行以下設定：

- **SSH 優化**:
  - **修改預設埠口**: 將 Port 22 改為隨機高位埠口 (例如: 22022)。
  - **停用密碼登入**: 僅允許 SSH Key 登入 (`PasswordAuthentication no`)。
  - **禁止 Root 登入**: 使用具備 sudo 權限的一般使用者登入 (`PermitRootLogin no`)。
- **防火牆控管 (UFW)**:
  - 僅允許必要的埠口: 80, 443, 以及變更後的 SSH 埠口。
  - `sudo ufw default deny incoming`
- **入侵預防 (Fail2Ban)**:
  - 安裝並啟用 `fail2ban` 來自動封鎖多次登入失敗的 IP。
