const crypto = require('crypto');
require('dotenv').config(); // Make sure dotenv is installed

const algorithm = 'aes-256-cbc';
const secret = process.env.ENCRYPTION_SECRET || 'default-secret-key';

function encrypt(text) {
const key = crypto.createHash('sha256').update(secret).digest();
const iv = crypto.randomBytes(16);
const cipher = crypto.createCipheriv(algorithm, key, iv);
let encrypted = cipher.update(text, 'utf8', 'hex');
encrypted += cipher.final('hex');
return { encrypted, iv: iv.toString('hex') };
}

module.exports = encrypt;
