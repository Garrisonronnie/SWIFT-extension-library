const fs = require('fs');
const isValidUser = require('./userCheck');

let imageLink = "";
try {
const cfg = JSON.parse(fs.readFileSync('userImageConfig.json', 'utf8'));
imageLink = cfg.customIconURL || '';
} catch {
imageLink = '';
}

if (!imageLink) {
console.warn("⚠️ No custom image configured. Run iconSelector.js");
imageLink = '';
}

function buildScript() {
const script = `
(function(){
function getRandomInt(max) { return Math.floor(Math.random()*max); }
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
dot.style.cssText = "position:fixed;bottom:10px;right:10px;width:12px;height:12px;background:#00ff88;border-radius:50%;z-index:9999;";
document.body.appendChild(dot);
console.log("Random:", getRandomInt(1000));
} else {
console.warn("❌ Not a verified user.");
}
})();
`;
fs.writeFileSync('autoScript.js', script);
}

buildScript();
console.log("✅ autoScript.js generated.");
