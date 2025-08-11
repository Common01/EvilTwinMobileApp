const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');

const app = express();
let port = process.env.PORT || 3000;


// Middleware
app.use(express.json());

// MySQL connection
const connection = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '1234',
    database: 'blueteam'
});

connection.connect((err) => {
    if (err) {
        console.error("MySQL connection error:", err);
        return;
    }
    console.log("Connected to MySQL");
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

// POST a new user
app.post('/api/users', async (req, res) => {
    const { username, email, passwords, descriptions, image, roles } = req.body;

    if (!username || !email || !passwords) {
        return res.status(400).json({ error: "Missing required fields" });
    }

    try {
        // 🔐 Hash the password
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(passwords, saltRounds);

        const query = `
            INSERT INTO users (username, email, passwords, descriptions, image, roles)
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        connection.query(
            query,
            [username, email, hashedPassword, descriptions, image, roles],
            (err, result) => {
                if (err) {
                    console.error("Error inserting user: ", err);
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

//register
app.post('/api/register', (req, res) => {
    const { username, email, passwords } = req.body;
    const roles = "User"; // ตั้งค่าค่า roles ตายตัว

    if (!username || !email || !passwords) {
        return res.status(400).json({ error: "Missing required fields" });
    }

    const query = `
        INSERT INTO users (username, email, passwords, roles)
        VALUES (?, ?, ?, ?)
    `;

    connection.query(query, [username, email, passwords, roles], (err, results) => {
        if (err) {
            console.error("Error inserting user:", err);
            return res.status(500).json({ error: "Internal Server Error" });
        }

        res.status(201).json({
            message: "User registered successfully",
            insertedId: results.insertId
        });
    });
});


app.listen(port, () => {
    console.log(`Server is running on port: ${port}`);
});
