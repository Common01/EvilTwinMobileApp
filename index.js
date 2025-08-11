const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
require('dotenv').config(); // โหลด .env ถ้ามี

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// MySQL connection
const connection = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',   // ใช้ environment variable
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '1234',
    database: process.env.DB_NAME || 'blueteam'
});

connection.connect((err) => {
    if (err) {
        console.error("MySQL connection error:", err);
        return;
    }
    console.log("Connected to MySQL");
});

// ✅ Route สำหรับเช็คสถานะ
app.get('/', (req, res) => {
    res.send('🚀 Server is running!');
});

// GET all users
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

// POST a new user (สำหรับ admin เพิ่มผู้ใช้)
app.post('/api/users', async (req, res) => {
    const { username, email, passwords, descriptions, image, roles } = req.body;

    if (!username || !email || !passwords) {
        return res.status(400).json({ error: "Missing required fields" });
    }

    try {
        const hashedPassword = await bcrypt.hash(passwords, 10);

        const query = `
            INSERT INTO users (username, email, passwords, descriptions, image, roles)
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        connection.query(
            query,
            [username, email, hashedPassword, descriptions, image, roles],
            (err, result) => {
                if (err) {
                    console.error("Error inserting user:", err);
                    return res.status(500).json({ error: "Internal Server Error" });
                }

                res.status(201).json({
                    msg: "User inserted successfully",
                    insertedId: result.insertId
                });
            }
        );
    } catch (err) {
        console.error("Error hashing password:", err);
        res.status(500).json({ error: "Failed to hash password" });
    }
});

// ✅ Register route
app.post('/api/register', async (req, res) => {
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
                console.error("Error inserting user:", err);
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

app.listen(port, () => {
    console.log(`Server is running on port: ${port}`);
});
