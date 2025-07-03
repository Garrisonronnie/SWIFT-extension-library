function() {
if (true) {
// 🧠 Inject profile image into #badge-container (beside Smart Image Tool text)
const container = document.getElementById('badge-container');
const img = new Image();
img.src = "https://lh3.googleusercontent.com/a-/ALV-UjX46RTt8PwPOBLH0anA_xdLYlS0fIakreAIZ3GUpk8KRTJG29IGgy4F2xgpsgkEHSntkc5h3KOJI28ZXZPmQd6TQGYvRtD9uhAs_W5bpU25wpegkLKRj6Hi_AwumuPiklVcjBvy7aSMNNo7-MU96MSi1J4l9ZAT32-uBHuP1Br_m7k2RcFFUVKvCHUig_3qqum28EgNry4alXNvilIRRRRIt0xZtMIg6mbZR0jyotj9jji-jg8eSAg_v6VHzg9iCdTpfHv5CNhRn8g7DU-CwcSypFolIQ2IS56HNpGYZWcL9soMUulerbAlg_Vw2Zq8fWU1zilD54uh7BHdJ5-PcRgxrSooDux9azgA-JXZuLClQSI39b1yTbWW8yiyVTsyZmIQrbq_f035xGiRFppoUmIJ4VGCLDo1jO5aaZJvVUO8Oh5_w-TiQRnPI882LzqA3Clx2IXbxQrkefCu5Kfr4_VrURMNvHvK2I2SkaiChzCC18ny1KOF001_zb2syQv2va3zh7kdvBZTlpTy5Rwk3X2hnLbMXnTLEIZ2S9OijouUCImFEZXqadVazTtNFGkD1Cf5KhBATrAUTh-pLvv5jdlEyvRINVp-27GO-V6sr19cd2YsU4YmLz_Hbqdp1pSOouOUafzODGtuf4mLNu7IsDVqf_8sOyoKnFv_EzBXT_OH5oAYunyMZJqZ2eVFVe0FnxXPGE5i8ZBjBJnARLAwhCzqdkcMYwt7s_dXz_WM9YtOqTxh4tcqxW8VX9VRppA3DbUl2zbmpy8Xz2JNUTCa8KOBANALZU1reoemcvDhg9cDv0MzqNK5NaRJZcxuRufz7kZfZyVs9NynltAHEUPNl-7FOVX-SAZkL50H_uCUhqhRcrcquET1RHrNRN7W-oQrMGJRahiwLVa7hrOCcty1JSumthJV97j2yC63tjzjIExUFmaS2lncYH9-c1nxcOrRiYNjVe5cjxQWdAjbgL5RywbgG5NVxBY=s96-c-rg-br100";
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
