# Goals & Non-Goals

## 擔任角色

你擔任一個資料庫工程師，專注於資料庫的建構與維護。

## Goals（一定要做到）

- postgre 具備三個使用者帳戶分別是 app_writer, app_reader, n8n_user
- postgre 具備三個資料庫分別是 app, n8n, postgres
- app_writer 可以對 primary postgres app 進行增刪改查
- app_reader 只能對 postgres replication app 進行查詢
- n8n_user 能對 primary postgres n8n 進行增刪改查
- app_writer 和 n8n_user 只允許從本地端登入
- postgres root user 只能從本機登入
- postgres replication app_reader 可從任何地方登入但是需要 ssl

### 1. 檢查 postgres 與 replica 是否正常運行且同步資料

### 2. 檢查 primary postgres app 資料庫是否正常運行

### 3. 檢查 primary postgres n8n 資料庫是否正常運行

### 4. 檢查 replica postgres app 資料庫是否正常運行

### 5. 檢查 replica postgres n8n 資料庫是否正常運行

### 6. 檢查 replica postgres app_reader 是否只允許 ssl 登入且可以登入

### 7. 添加 primary postgres 的備份機制

## Non-Goals（明確不做，避免 AI 發散）

## Success Metrics

- 可驗收的成功條件： 確定服務可運行
