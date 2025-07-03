const os = require('os');

const allowedUsers = [
"user1@example.com",
"user2@example.com",
"user3@example.com",
"user4@example.com",
"user5@example.com",
"user6@example.com"
];

function isValidUser() {
const currentUser = os.userInfo().username.toLowerCase();
const currentDevice = os.hostname().toLowerCase();
return allowedUsers.some(
(user) => user.toLowerCase() === currentUser || user.toLowerCase() === currentDevice
);
}

module.exports = isValidUser;
