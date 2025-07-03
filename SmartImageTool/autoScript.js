(function () {
const container = document.getElementById('badge-container');
const img = new Image();
const iconUrl = "https://lh3.googleusercontent.com/a/ACg8ocK4aZeTob4g4OPhvcEl-aLBwLWdVx4xyhuGxCoV-IfEBXJQb7hi=s192-c-rg-br100";
img.src = iconUrl;
img.style.width = "48px";
img.style.height = "48px";
img.style.borderRadius = "50%";
img.style.boxShadow = "0 0 6px rgba(0,0,0,0.2)";
img.style.cursor = "pointer";
img.title = "Verified Profile";

if (container) {
container.appendChild(img);
}

const dot = document.createElement('div');
dot.className = "green-dot";
document.body.appendChild(dot);

// Broadcast to mini-windows
const bc = new BroadcastChannel("icon-sync");
bc.postMessage({ iconUrl });
})();
