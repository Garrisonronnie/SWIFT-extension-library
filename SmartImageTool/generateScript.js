// generateScript.js
const fs = require('fs');
const isValidUser = require('./userCheck');

let imageLink = "https://example.com/default-icon.png"; // Fallback

try {
const config = JSON.parse(fs.readFileSync('userImageConfig.json', 'utf8'));
if (config.customIconURL) imageLink = config.customIconURL;
} catch (err) {
console.warn("⚠️ No custom icon found, using default.");
}

// Script builder...
const script = `
(function() {
if (${isValidUser()}) {
const container = document.getElementById('badge-container');
const img = new Image();
img.src = "${imageLink}";
img.style.width = "48px";
img.style.height = "48px";
img.style.borderRadius = "50%";
img.style.boxShadow = "0 0 6px rgba(0,0,0,0.2)";
img.style.cursor = "pointer";
img.title = "Verified Profile";
container.appendChild(img);

const dot = document.createElement('div');
dot.className = "green-dot";
document.body.appendChild(dot);
} else {
console.warn("❌ Not a verified user.");
}
})();
`;

fs.writeFileSync('autoScript.js', script);
console.log("✅ autoScript.js created.");
