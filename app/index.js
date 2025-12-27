const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = process.env.PORT || 3000;

const fs = require('fs');

// 資料庫連線配置
const poolConfig = {
  host: process.env.DB_HOST,     // 指向 postgres-replica
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // 連線池限制
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
};

// 如果環境中有憑證路徑，則啟用 mTLS
if (process.env.DB_SSL_CA) {
  poolConfig.ssl = {
    rejectUnauthorized: true,
    ca: fs.readFileSync(process.env.DB_SSL_CA).toString(),
    key: fs.readFileSync(process.env.DB_SSL_KEY).toString(),
    cert: fs.readFileSync(process.env.DB_SSL_CERT).toString(),
  };
} else {
  poolConfig.ssl = false;
}

const pool = new Pool(poolConfig);

const API_KEY = process.env.API_SECRET_KEY;

// 健康檢查（免 API Key）
app.get('/health', (req, res) => {
  res.json({ status: 'up', timestamp: new Date() });
});

// 安全性：檢查 API Key
app.use((req, res, next) => {
  const userKey = req.headers['x-api-key'];
  if (userKey && userKey === API_KEY) {
    next();
  } else {
    res.status(403).json({ error: 'Forbidden: Invalid API Key' });
  }
});

// 查詢資料範例（唯讀存取 postgres-replica）
app.get('/data', async (req, res) => {
  const { table = 'users', limit = 10 } = req.query;
  
  // 安全限制：避免 SQL Injection (這裡僅示範，實務上應使用更嚴格的白名單)
  const safeLimit = parseInt(limit, 10) || 10;
  
  try {
    // 範例查詢 - 請根據實務資料表調整
    const result = await pool.query(`SELECT * FROM ${table} LIMIT $1`, [safeLimit]);
    res.json({
      count: result.rowCount,
      data: result.rows
    });
  } catch (err) {
    console.error('Database Error:', err.message);
    res.status(500).json({ error: 'Database Error', details: err.message });
  }
});

app.listen(port, () => {
  console.log(`API Bridge running on http://localhost:${port}`);
});