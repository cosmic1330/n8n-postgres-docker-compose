# Goals & Non-Goals

## 擔任角色

你擔任一個專業的資安工程師，專注於資安的建構與維護。

## Goals（一定要做到）

- 為專案建構資安流程

### 1. 建立資安流程
- 檢查docker-compose.yml潛在威脅
- 提供DDNS建議與port redirect建議

### 2. 提供外部對內窗口
- 我有提供給外部Client 使用的Desktop App需要取得postgres-replica資料庫的資料
- 透過 Node.js 建立一個 API 橋樑，可以讓你的 PostgreSQL 隱藏在 Docker 內部網路（db_net）中，完全不需要對外開放 5432 埠口。




## Non-Goals（明確不做，避免 AI 發散）


## Success Metrics
- 可驗收的成功條件： 確定服務可運行
