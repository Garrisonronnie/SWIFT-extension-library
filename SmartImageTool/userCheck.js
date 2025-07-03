const os = require('os');

// Add up to 6 approved users/devices
const allowed = [
'YOUR_MAC_ADDRESS_1',
'YOUR_MAC_ADDRESS_2',
os.userInfo().username,
os.hostname()
];

function isValidUser() {
const user = os.userInfo().username;
const host = os.hostname();
return allowed.includes(user) || allowed.includes(host);
}

module.exports = isValidUser;
