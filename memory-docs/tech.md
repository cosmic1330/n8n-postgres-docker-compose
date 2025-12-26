# Technology Stack

## 基礎架構 (Infrastructure)

- **容器化平台**: Docker, Docker Compose
- **作業系統**: Ubuntu 22.04 LTS (推薦宿主機)
- **反向代理**: Nginx (最新版)
- **DNS**: 使用 Google DNS (8.8.8.8) 與 Cloudflare DNS (1.1.1.1) 確保連線穩定

## 資料庫與連線管理 (Database & Connection Pooling)

- **主要資料庫 (Primary)**: PostgreSQL 16
  - `wal_level`: replica
  - `max_wal_senders`: 10
  - `max_replication_slots`: 10
- **複製品資料庫 (Replica)**: PostgreSQL 16 (Hot Standby)
- **連線池管理 (PgBouncer)**:
  - `pgbouncer-n8n`: 提供給 n8n 使用，模式為 `session`
  - `pgbouncer-app`: 提供給一般應用程式使用，模式為 `transaction` (支援大量連線)

## 應用程式層 (Application Layer)

- **n8n**: 基於 `n8nio/n8n:latest` 的自定義映像檔
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
