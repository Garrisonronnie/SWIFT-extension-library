function() {
if (true) {
// 🧠 Inject profile image into #badge-container (beside Smart Image Tool text)
const container = document.getElementById('badge-container');
const img = new Image();
img.src = "https://lh3.googleusercontent.com/a/ACg8ocK4aZeTob4g4OPhvcEl-aLBwLWdVx4xyhuGxCoV-IfEBXJQb7hi=s192-c-rg-br100"
img.style.width = "48px";
img.style.height = "48px";
img.style.borderRadius = "50%";
img.style.boxShadow = "0 0 6px rgba(0,0,0,0.2)";
img.style.cursor = "pointer";
img.title = "Verified Profile";

container.appendChild(img);

// 🟢 Add green dot in bottom right
const dot = document.createElement('div');
dot.style.cssText = "position:fixed;bottom:10px;right:10px;width:12px;height:12px;background:#00ff88;border-radius:50%;z-index:9999;";
document.body.appendChild(dot);
} else {
console.warn("❌ Not a verified user.");
}
})();
