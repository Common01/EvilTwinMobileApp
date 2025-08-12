const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
require('dotenv').config();
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MySQL connection
const connection = mysql.createConnection({
  host: process.env.DB_HOST,        // ตัวอย่าง: 'your-db-host'
  user: process.env.DB_USER,        // ตัวอย่าง: 'your-db-user'
  password: process.env.DB_PASS,    // ตัวอย่าง: 'your-db-password'
  database: process.env.DB_NAME,    // ตัวอย่าง: 'your-db-name'
  connectTimeout: 10000,
});

connection.connect((err) => {
  if (err) {
    console.error("MySQL connection error:", err);
    return;
  }
  console.log("✅ Connected to MySQL");
});

// ----------------------------- ROUTES -----------------------------

// ตรวจสอบว่าเซิร์ฟเวอร์ทำงานอยู่
app.get('/', (req, res) => {
  res.send('🚀 Server is running!');
});

// ✅ ดึงผู้ใช้ทั้งหมด
app.get('/api/users', (req, res) => {
  const query = "SELECT * FROM users";
  connection.query(query, (err, results) => {
    if (err) {
      console.error("Error fetching users:", err);
      return res.status(500).json({ error: "Internal Server Error" });
    }
    res.json({ msg: "Data fetched successfully", data: results });
  });
});

// ✅ สมัครสมาชิก
app.post('/api/register', async (req, res) => {
  console.log("📥 Register Request Body:", req.body);

  const { username, email, passwords } = req.body;
  const roles = "User";

  if (!username || !email || !passwords) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    const hashedPassword = await bcrypt.hash(passwords, 10);

    const query = `
      INSERT INTO users (username, email, passwords, roles)
      VALUES (?, ?, ?, ?)
    `;

    connection.query(query, [username, email, hashedPassword, roles], (err, results) => {
      if (err) {
        console.error("❌ Error inserting user:", err);
        return res.status(500).json({ error: "Internal Server Error" });
      }

      res.status(201).json({
        message: "User registered successfully",
        insertedId: results.insertId
      });
    });
  } catch (err) {
    console.error("Error hashing password:", err);
    res.status(500).json({ error: "Failed to hash password" });
  }
});

// ✅ ล็อกอิน
app.post('/api/login', (req, res) => {
  const { email, passwords } = req.body;

  if (!email || !passwords) {
    return res.status(400).json({ error: "กรุณากรอกอีเมลและรหัสผ่าน" });
  }

  const sql = `SELECT * FROM users WHERE email = ?`;
  connection.query(sql, [email], async (err, results) => {
    if (err) {
      console.error("Error fetching user:", err);
      return res.status(500).json({ error: "Internal Server Error" });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: "อีเมลหรือรหัสผ่านผิด" });
    }

    const user = results[0];
    const match = await bcrypt.compare(passwords, user.passwords);
    if (!match) {
      return res.status(401).json({ error: "อีเมลหรือรหัสผ่านผิด" });
    }

    const { passwords: _, ...safeUser } = user; // ลบรหัสผ่านก่อนส่งกลับ

    res.status(200).json({ message: "เข้าสู่ระบบสำเร็จ", user: safeUser });
  });
});

// ----------------------------- START SERVER -----------------------------
app.listen(port, () => {
  console.log(`🌐 Server is running on port: ${port}`);
});
