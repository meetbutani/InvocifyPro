const express = require("express");
const router = express.Router();
require('dotenv').config();
const mysql = require('mysql2');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// const connection = mysql.createConnection(process.env.DATABASE_URL)
const connection = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
    ssl: {
        rejectUnauthorized: true
    }
})
// console.log('Connected to PlanetScale!')
// connection.end()

// Multer configuration for file upload
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

router.get('/', (req, res) => {
    res.status(200).json({ message: 'API Called.' });
});

router.post('/login', (req, res) => {
    const { email, password } = req.body;
    // console.log(email + " " + password);
    connection.query(
        'SELECT * FROM users WHERE email = ? AND password = ?',
        [email, password],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.', ok: false });
            } else {
                if (results.length > 0) {
                    // res.status(200).json({ message: 'Login successful.', ok: true, data: { id: results[0]['id'], shopName: results[0]['shopName'], email: results[0]['email']} });
                    res.status(200).json({ message: 'Login successful.', ok: true, data: { ...results[0], 'password': undefined } });
                } else {
                    res.status(401).json({ message: 'Login failed.', ok: false });
                }
            }
        }
    );
});

router.post('/register', (req, res) => {
    // const { shopName, email, password } = req.body;
    const { email, password } = req.body;

    // Check if the email already exists in the database
    connection.query(
        'SELECT * FROM users WHERE email = ?',
        [email],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            }
            else if (results.length > 0) {
                // If the email already exists, return an error response
                res.status(400).json({ message: 'Email already exists.' });
            }
            else {
                // If the email doesn't exist, proceed with registration
                connection.query(
                    // 'INSERT INTO users (shopName, email, password) VALUES (?, ?, ?)',
                    'INSERT INTO users (email, password) VALUES (?, ?)',
                    [email, password],
                    // [shopName, email, password],
                    (error, results, fields) => {
                        if (error) {
                            console.error(error);
                            res.status(500).json({ message: 'Internal server error.' });
                        } else {
                            res.status(200).json({ message: 'Registration successful.' });
                        }
                    }
                );
            }
        }
    );
});

// API to store product data in the database
router.post('/storeProduct', (req, res) => {
    const { userid, qrCode, productName, sellingPrice, mrpPrice, costPrice, currentStock, alertStockLimit, stockUnit } = req.body;

    // Example query to insert data into the database
    connection.query(
        'INSERT INTO products (userid, qrCode, productName, sellingPrice, mrpPrice, costPrice, currentStock, alertStockLimit, stockUnit) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [userid, qrCode, productName, sellingPrice, mrpPrice || 0, costPrice || 0, currentStock || 0, alertStockLimit || 0, stockUnit],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ message: 'Product stored successfully.' });
            }
        }
    );
});

// API to check if the product QR Code/Unique ID is repeating
router.post('/checkQRCode', (req, res) => {
    const { qrCode, userid } = req.body;

    // Example query to check if the QR Code already exists in the database
    connection.query(
        'SELECT * FROM products WHERE qrCode = ? and userid = ?',
        [qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.length > 0) {
                    res.status(200).json({ message: 'QR Code already exists.', exists: true });
                } else {
                    res.status(200).json({ message: 'QR Code is unique.', exists: false });
                }
            }
        }
    );
});

// API to check if the product QR Code/Unique ID is repeating
router.post('/getQRDetails', (req, res) => {
    const { qrCode } = req.body;

    // Example query to check if the QR Code already exists in the database
    connection.query(
        'SELECT * FROM products WHERE qrCode = ?',
        [qrCode],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.length > 0) {
                    res.status(200).json({ message: 'QR detail available.', exists: true, data: { qrCode: results[0]['qrCode'], productName: results[0]['productName'], mrpPrice: results[0]['mrpPrice'] } });
                } else {
                    res.status(200).json({ message: 'QR detail not available.', exists: false });
                }
            }
        }
    );
});

// API to check if the product QR Code/Unique ID is repeating
router.post('/getProductData', (req, res) => {
    const { qrCode, userid } = req.body;

    // Example query to check if the QR Code already exists in the database
    connection.query(
        'SELECT qrCode, productName, sellingPrice, currentStock FROM products WHERE qrCode = ? and userid = ?',
        [qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                // console.log(results);
                if (results.length > 0) {
                    res.status(200).json({ message: 'Product finded.', exists: true, data: results[0] });
                } else {
                    res.status(200).json({ message: 'Product not found.', exists: false });
                }
            }
        }
    );
});

// API to check if the product QR Code/Unique ID is repeating
router.post('/getProductAllData', (req, res) => {
    const { qrCode, userid } = req.body;

    // Example query to check if the QR Code already exists in the database
    connection.query(
        'SELECT * FROM products WHERE qrCode = ? and userid = ?',
        [qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                // console.log(results);
                if (results.length > 0) {
                    res.status(200).json({ message: 'Product finded.', exists: true, data: results[0] });
                } else {
                    res.status(200).json({ message: 'Product not found.', exists: false });
                }
            }
        }
    );
});

// API to check if the product QR Code/Unique ID is repeating
router.post('/getAllProductData', (req, res) => {
    const { userid } = req.body;

    // Example query to check if the QR Code already exists in the database
    connection.query(
        'SELECT qrCode, productName, sellingPrice, currentStock FROM products WHERE userid = ?',
        [userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                // console.log(results);
                if (results.length > 0) {
                    res.status(200).json({ message: 'All Product Retrived.', exists: true, data: results });
                } else {
                    res.status(200).json({ message: 'Products not found.', exists: false });
                }
            }
        }
    );
});

// PUT request handler for updating product details
router.put('/updateProduct', (req, res) => {
    const { userid, qrCode, productName, sellingPrice, mrpPrice, costPrice, currentStock, alertStockLimit, stockUnit } = req.body;

    // Example query to update product data in the database
    connection.query(
        `UPDATE products SET
       productName = ?,
       sellingPrice = ?,
       mrpPrice = ?,
       costPrice = ?,
       currentStock = ?,
       alertStockLimit = ?,
       stockUnit = ?
       WHERE qrCode = ? AND userid = ?`,
        [productName, sellingPrice, mrpPrice, costPrice, currentStock, alertStockLimit, stockUnit, qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error('Error updating product:', error);
                res.status(500).json({ error: 'An error occurred while updating the product' });
            } else {
                if (results.affectedRows > 0) {
                    res.status(200).json({ message: 'Product updated successfully' });
                } else {
                    res.status(404).json({ error: 'Product not found' });
                }
            }
        }
    );
});


// API to retrieve all products for a given user ID
router.get('/getProducts/:userId', (req, res) => {
    const userId = req.params.userId;

    // Example query to retrieve products for the specified user ID
    connection.query(
        'SELECT * FROM products WHERE userid = ?',
        [userId],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ products: results });
            }
        }
    );
});

// API to store shop information
router.post('/storeShopInfo', (req, res) => {
    const { userId, shopName, shopAddress, shopEmail, shopPhone, shopWebsite, shopGSTNo } = req.body;

    // Insert or update shop information into the database
    connection.query(
        'INSERT INTO shop_info (user_id, shop_name, shop_address, shop_email, shop_phone, shop_website, shop_gst_no) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE shop_name = VALUES(shop_name), shop_address = VALUES(shop_address), shop_email = VALUES(shop_email), shop_phone = VALUES(shop_phone), shop_website = VALUES(shop_website), shop_gst_no = VALUES(shop_gst_no)',
        [userId, shopName, shopAddress, shopEmail, shopPhone, shopWebsite, shopGSTNo],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ message: 'Shop information stored successfully.' });
            }
        }
    );
});

// API to upload shop logo
router.post('/uploadShopLogo', upload.single('logo'), (req, res) => {
    if (!req.file) {
        res.status(400).json({ message: 'No file uploaded' });
        return;
    }

    const tempPath = req.file.path;
    // const targetPath = path.join(__dirname, './uploads/shoplogos/' + req.file.filename);
    const targetPath = path.join(__dirname, './uploads/shoplogos/' + req.body.email + ".png");

    fs.rename(tempPath, targetPath, (err) => {
        if (err) {
            console.error(err);
            res.status(500).json({ message: 'Error occurred while uploading file' });
        } else {
            // res.status(200).json({ message: 'File uploaded successfully', imagePath: targetPath });
            res.status(200).json({ message: 'File uploaded successfully' });
        }
    });
});

// API to retrieve shop information for a user
router.get('/getShopInfo/:userId', (req, res) => {
    const userId = req.params.userId;

    // Retrieve shop information from the database
    connection.query(
        'SELECT * FROM shop_info WHERE user_id = ?',
        [userId],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.length > 0) {
                    res.status(200).json({ message: 'Shop information retrieved successfully', shopInfo: results[0] });
                } else {
                    res.status(404).json({ message: 'Shop information not found for the user' });
                }
            }
        }
    );
});

module.exports = router;
