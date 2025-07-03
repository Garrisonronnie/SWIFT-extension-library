const fs = require('fs');
const rl = require('readline').createInterface({ input: process.stdin, output: process.stdout });

rl.question('Enter your custom icon URL: ', url => {
if (!url.startsWith('http')) { console.log('❌ Must start with http'); rl.close(); return; }
fs.writeFileSync('userImageConfig.json', JSON.stringify({ customIconURL: url }, null, 2));
console.log('✅ Saved as userImageConfig.json'); rl.close();
});
