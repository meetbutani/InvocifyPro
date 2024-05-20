const express = require("express");
const router = express.Router();
require('dotenv').config();
const { Pool } = require('pg');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_DATABASE,
    ssl: {
        rejectUnauthorized: true
    }
});

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
    res.status(200).json({ message: 'API Called: ' + Date.now() });
});

router.post('/login', (req, res) => {
    const { email, password } = req.body;
    // console.log(email + " " + password);
    pool.query(
        'SELECT * FROM users WHERE email = $1 AND password = $2',
        [email, password],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.', ok: false });
            } else {
                if (results.rows.length > 0) {
                    // res.status(200).json({ message: 'Login successful.', ok: true, data: { id: results.rows[0]['id'], shopName: results.rows[0]['shopName'], email: results.rows[0]['email']} });
                    res.status(200).json({ message: 'Login successful.', ok: true, data: { ...results.rows[0], 'password': undefined } });
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
    pool.query(
        'SELECT * FROM users WHERE email = $1',
        [email],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            }
            else if (results.rows.length > 0) {
                // If the email already exists, return an error response
                res.status(400).json({ message: 'Email already exists.' });
            }
            else {
                // If the email doesn't exist, proceed with registration
                pool.query(
                    // 'INSERT INTO users (shopName, email, password) VALUES (?, ?, ?)',
                    'INSERT INTO users (email, password) VALUES ($1, $2)',
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

router.post('/changePassword', (req, res) => {
    const { email, newPassword } = req.body;

    // Check if the email exists in the database
    pool.query(
        'SELECT * FROM users WHERE email = $1',
        [email],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else if (results.rows.length === 0) {
                res.status(404).json({ message: 'Email not found.' });
            } else {
                // Update the user's password
                pool.query(
                    'UPDATE users SET password = $1 WHERE email = $2',
                    [newPassword, email],
                    (error, results, fields) => {
                        if (error) {
                            console.error(error);
                            res.status(500).json({ message: 'Internal server error.' });
                        } else {
                            res.status(200).json({ message: 'Password changed successfully.' });
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
    pool.query(
        'INSERT INTO products (userid, "qrCode", "productName", "sellingPrice", "mrpPrice", "costPrice", "currentStock", "alertStockLimit", "stockUnit") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
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
    pool.query(
        'SELECT * FROM products WHERE "qrCode" = $1 and userid = $2',
        [qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.rows.length > 0) {
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
    pool.query(
        'SELECT * FROM products WHERE "qrCode" = $1',
        [qrCode],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.rows.length > 0) {
                    res.status(200).json({ message: 'QR detail available.', exists: true, data: { qrCode: results.rows[0]['qrCode'], productName: results.rows[0]['productName'], mrpPrice: results.rows[0]['mrpPrice'] } });
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
    pool.query(
        'SELECT "qrCode", "productName", "sellingPrice", "currentStock" FROM products WHERE "qrCode" = $1 and userid = $2',
        [qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                // console.log(results);
                if (results.rows.length > 0) {
                    res.status(200).json({ message: 'Product finded.', exists: true, data: results.rows[0] });
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
    pool.query(
        'SELECT * FROM products WHERE "qrCode" = $1 and userid = $2',
        [qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                // console.log(results);
                if (results.rows.length > 0) {
                    res.status(200).json({ message: 'Product finded.', exists: true, data: results.rows[0] });
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
    pool.query(
        'SELECT "qrCode", "productName", "sellingPrice", "currentStock" FROM products WHERE userid = $1',
        [userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.rows.length > 0) {
                    res.status(200).json({ message: 'All Product Retrived.', exists: true, data: results.rows });
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
    pool.query(
        `UPDATE products SET
            "productName" = $1,
            "sellingPrice" = $2,
            "mrpPrice" = $3,
            "costPrice" = $4,
            "currentStock" = $5,
            "alertStockLimit" = $6,
            "stockUnit" = $7
            WHERE "qrCode" = $8 AND userid = $9`
        ,
        [productName, sellingPrice, mrpPrice, costPrice, currentStock, alertStockLimit, stockUnit, qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error('Error updating product:', error);
                res.status(500).json({ error: 'An error occurred while updating the product' });
            } else {
                // console.log(results)
                if (results.rowCount > 0) {
                    res.status(200).json({ message: 'Product updated successfully' });
                } else {
                    res.status(404).json({ error: 'Product not found' });
                }
            }
        }
    );
});

// DELETE request handler for deleting product details
router.delete('/deleteProduct', (req, res) => {
    const { userid, qrCode } = req.body;

    // Example query to update product data in the database
    pool.query(
        `DELETE FROM products WHERE "qrCode"=$1 AND userid = $2`,
        [qrCode, userid],
        (error, results, fields) => {
            console.log(results)
            if (error) {
                console.error('Error deleting product:', error);
                res.status(500).json({ error: 'An error occurred while deleting the product' });
            } else {
                // console.log(results)
                if (results.rowCount > 0) {
                    res.status(200).json({ message: 'Product deleted successfully' });
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
    pool.query(
        'SELECT * FROM products WHERE userid = $1 ORDER BY "productName"',
        [userId],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ products: results.rows });
            }
        }
    );
});

// API to retrieve all low stock products for a given user ID
router.get('/getLowStockProducts/:userId', (req, res) => {
    const userId = req.params.userId;

    // Example query to retrieve products for the specified user ID
    pool.query(
        'SELECT * FROM products WHERE userid = $1 AND "currentStock" <= "alertStockLimit" ORDER BY "currentStock" - "alertStockLimit"',
        [userId],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ products: results.rows });
            }
        }
    );
});

// API to store shop information
router.post('/storeShopInfo', (req, res) => {
    const { userId, shopName, shopAddress, shopEmail, shopPhone, shopWebsite, shopGSTNo, shopTerms } = req.body;

    // Insert or update shop information into the database
    pool.query(`INSERT INTO shop_info (user_id, shop_name, shop_address, shop_email, shop_phone, shop_website, shop_gst_no, shop_terms) 
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
                ON CONFLICT (user_id) DO UPDATE 
                SET 
                    shop_name = EXCLUDED.shop_name, 
                    shop_address = EXCLUDED.shop_address, 
                    shop_email = EXCLUDED.shop_email, 
                    shop_phone = EXCLUDED.shop_phone, 
                    shop_website = EXCLUDED.shop_website, 
                    shop_gst_no = EXCLUDED.shop_gst_no,
                    shop_terms = EXCLUDED.shop_terms;`,
        [userId, shopName, shopAddress, shopEmail, shopPhone, shopWebsite, shopGSTNo, shopTerms],
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
    pool.query(
        'SELECT * FROM shop_info WHERE user_id = $1',
        [userId],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.rows.length > 0) {
                    res.status(200).json({ message: 'Shop information retrieved successfully', shopInfo: results.rows[0] });
                } else {
                    res.status(404).json({ message: 'Shop information not found for the user' });
                }
            }
        }
    );
});

// API to store generated invoices and update stock
router.post('/invoices', (req, res) => {
    const { invoice_no, shop_id, shop_name, shop_address, shop_email, shop_phone, shop_gst_no, cust_name, cust_address, cust_phone, cust_email, invoice_date, due_date, subtotal, discount, tax_rate, total_amount, products, needToUpdate } = req.body;

    // Insert the invoice data into the invoices table
    pool.query(
        `INSERT INTO invoices (
        invoice_no, shop_id, shop_name, shop_address, shop_email, shop_phone, shop_gst_no, 
        cust_name, cust_address, cust_phone, cust_email, 
        invoice_date, due_date, subtotal, discount, tax_rate, total_amount, products
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)`,
        [invoice_no, shop_id, shop_name, shop_address, shop_email, shop_phone, shop_gst_no, cust_name, cust_address, cust_phone, cust_email, invoice_date, due_date, subtotal, discount, tax_rate, total_amount, JSON.stringify(products)],
        (error, results) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                // Update the current stock of the affected products
                let updatesCompleted = 0;
                needToUpdate.forEach(item => {
                    pool.query(
                        `UPDATE products SET "currentStock" = "currentStock" - $1 WHERE userid = $2 and "qrCode" = $3`,
                        [item[1], shop_id, item[0]],
                        (error, results) => {
                            if (error) {
                                console.error(error);
                                res.status(500).json({ message: 'Internal server error.' });
                            } else {
                                updatesCompleted++;
                                if (updatesCompleted === needToUpdate.length) {
                                    res.status(200).json({ message: 'Invoice created successfully.' });
                                }
                            }
                        }
                    );
                });
            }
        }
    );
});

// Retrieve Invoice Endpoint
router.get('/invoices/:shop_id/:invoiceNo', (req, res) => {
    const shop_id = req.params.shop_id;
    const invoiceNo = req.params.invoiceNo;

    pool.query(
        'SELECT * FROM invoices WHERE invoice_no = $1 AND shop_id = $2',
        [invoiceNo, shop_id],
        (error, results) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.rows.length > 0) {
                    const invoiceData = results.rows[0];
                    invoiceData.products = JSON.parse(invoiceData.products);
                    res.status(200).json({ message: 'Invoice retrieved successfully.', invoiceData });
                } else {
                    res.status(404).json({ message: 'Invoice not found.' });
                }
            }
        }
    );
});

// Retrieve all Invoices Endpoint
router.get('/invoices/:shop_id', (req, res) => {
    const shop_id = req.params.shop_id;

    pool.query(
        'SELECT * FROM invoices WHERE shop_id = $1',
        [shop_id],
        (error, results) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ message: 'All invoices retrieved successfully.', invoices: results.rows });
            }
        }
    );
});

router.post('/storeCustomQRCode', (req, res) => {
    const { userid, qrCode, productName, sellingPrice } = req.body;

    pool.query(
        'INSERT INTO custom_qr_codes (userid, qrcode, product_name, selling_price) VALUES ($1, $2, $3, $4)',
        [userid, qrCode, productName, sellingPrice],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json({ message: 'Custom QR code stored successfully.' });
            }
        }
    );
});

router.get('/getCustomQRCodes/:userid', (req, res) => {
    const userid = req.params.userid;

    pool.query(
        'SELECT * FROM custom_qr_codes WHERE userid = $1',
        [userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                res.status(200).json(results.rows);
            }
        }
    );
});

router.put('/updateCustomQRCode', (req, res) => {
    const { userid, qrCode, productName, sellingPrice } = req.body;

    pool.query(
        'UPDATE custom_qr_codes SET product_name = $1, selling_price = $2 WHERE qrcode = $3 and userid = $4',
        [productName, sellingPrice, qrCode, userid],
        (error, results, fields) => {
            if (error) {
                console.error(error);
                res.status(500).json({ message: 'Internal server error.' });
            } else {
                if (results.rowCount > 0) {
                    res.status(200).json({ message: 'Custom QR code updated successfully.' });
                } else {
                    res.status(404).json({ message: 'Custom QR code not found.' });
                }
            }
        }
    );
});


module.exports = router;
