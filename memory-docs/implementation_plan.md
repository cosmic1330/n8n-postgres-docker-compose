# Implementation Plan - Documentation Update

## Goals

- Complete `memory-docs/tech.md`
- Complete `memory-docs/architecture.md`

## Proposed Changes

### 1. Update Tech Stack (`tech.md`)

- Document Docker Compose environment.
- Document PostgreSQL 18 with Primary/Replica architecture.
- Document PgBouncer (n8n & App pools).
- Document n8n custom image with Puppeteer and Chromium.
- Document Nginx reverse proxy.

### 2. Update Architecture (`architecture.md`)

- Draw component relationship diagram.
- Explain database replication flow.
- Detail networking and volume mappings.
- Provide directory tree structure.

## Status

- [x] Task 1: Complete tech.md
- [x] Task 2: Complete architecture.md

## Result

- **Success**: Architecture and Technology documentation are fully completed and verified against the codebase.

---

# Implementation Plan - n8n-postgres-docker-compose Security & Bridge

## Goals

- 為專案建構資安流程，檢查 `docker-compose.yml` 潛在威脅。
- 提供 DDNS 與 Port Redirect 建議。
- 透過 Node.js 建立一個 API 橋樑，隱藏 PostgreSQL 於 Docker 內部網路。

## Proposed Changes

### 1. Security Analysis & Infrastructure

- **[MODIFY] [docker-compose.yml](file:///c:/Users/833368/strc/n8n-postgres-docker-compose/docker-compose.yml)**

  - 移除所有資料庫埠口 (5432, 5433) 的直接埠口映射 (`ports`)。
  - 移除 n8n 埠口 (5678) 的直接映射，改經由 Nginx。
  - 強化 `restart` 策略與資源限制。
  - 將 `api-bridge` 加入內部網路。

- **[MODIFY] [nginx/conf.d/ddns.conf](file:///c:/Users/833368/strc/n8n-postgres-docker-compose/nginx/conf.d/ddns.conf)**
  - 配置 `/api` 路徑轉發至 `api-bridge` 服務。
  - 確保 SSL 加密應用於所有外部存取。

### 2. API Bridge Implementation

- **[NEW] [app/Dockerfile](file:///c:/Users/833368/strc/n8n-postgres-docker-compose/app/Dockerfile)**

  - 建立輕量化 Node.js 映像檔用於運行 `api-bridge`。

- **[MODIFY] [app/index.js](file:///c:/Users/833368/strc/n8n-postgres-docker-compose/app/index.js)**
  - 改進錯誤處理與日誌記錄。
  - 增加動態查詢支援或參數化查詢以符合 Desktop App 需求。
  - 確保連線至 `postgres-replica`（唯讀分流）。

### 3. Documentation & Recommendations

- **[MODIFY] [memory-docs/tech.md](file:///c:/Users/833368/strc/n8n-postgres-docker-compose/memory-docs/tech.md)**
  - 新增 API Bridge 作為安全存取層。
- **[MODIFY] [memory-docs/architecture.md](file:///c:/Users/833368/strc/n8n-postgres-docker-compose/memory-docs/architecture.md)**
  - 更新架構圖，加入 API Bridge 與安全界限。

## Verification Plan

### Automated Tests

- 檢查 `docker-compose.yml` 語法：`docker compose config`.
- API 功能測試：使用 `curl` 測試 API Key 驗證與資料讀取。

### Manual Verification

- 使用 `netstat` 或 `nmap` 確認 5432, 5433 等埠口在宿主機上不可達。
- 登入 n8n UI 確認流程運作正常。
- 測試 API `/data` 路徑，確認可獲取 `postgres-replica` 資料。

---

## Result

- **Success**: 資安強化流程已建立，API Bridge 佈署完成，且所有資料庫埠口已成功隱藏。
