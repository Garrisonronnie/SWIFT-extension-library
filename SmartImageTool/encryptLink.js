const crypto = require('crypto');

const algorithm = 'aes-256-cbc';
const secret = 'This iPhone privacy.';

function encrypt(text) {
const key = crypto.createHash('sha256').update(secret).digest();
const iv = crypto.randomBytes(16);
const cipher = crypto.createCipheriv(algorithm, key, iv);
let encrypted = cipher.update(text, 'utf8', 'hex');
encrypted += cipher.final('hex');
return { encrypted, iv: iv.toString('hex') };
}

module.exports = encrypt;
