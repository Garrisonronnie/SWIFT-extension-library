// setCustomIcon.js
const fs = require('fs');
const readline = require('readline');

const rl = readline.createInterface({
input: process.stdin,
output: process.stdout
});

rl.question('🔗 Enter your custom icon URL: ', url => {
if (!url.startsWith('http')) {
console.log('❌ Invalid URL. Must start with http or https.');
rl.close();
return;
}

const config = { customIconURL: url };
fs.writeFileSync('userImageConfig.json', JSON.stringify(config, null, 2));
console.log('✅ Icon URL saved to userImageConfig.json');
rl.close();
});
