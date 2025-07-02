const os = require('os');

const allowedUsers = [
'ronniegarrison82@icloud.com',
os.hostname(),
os.userInfo().username
];

function isValidUser() {
const current = os.userInfo().username;
const device = os.hostname();
return allowedUsers.includes(current) || allowedUsers.includes(device);
}

module.exports = isValidUser;