const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

// 從環境變數讀取資料庫連線資訊
const pool = new Pool({
  host: process.env.DB_HOST,     // 將指向 docker 中的 postgres-replica
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: false // 內部網路連線可不開 SSL
});

// 簡易安全機制：檢查 API Key
const API_KEY = process.env.API_SECRET_KEY;

app.use((req, res, next) => {
  const userKey = req.headers['x-api-key'];
  if (userKey && userKey === API_KEY) {
    next();
  } else {
    res.status(403).json({ error: 'Forbidden: Invalid API Key' });
  }
});

// 定義資料查詢路徑
app.get('/data', async (req, res) => {
  try {
    // 範例：查詢前 10 筆資料
    const result = await pool.query('SELECT * FROM your_table LIMIT 10');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database Error' });
  }
});

app.listen(port, () => {
  console.log(`API Bridge listening at http://localhost:${port}`);
});