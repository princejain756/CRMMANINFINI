const bcrypt = require('bcrypt');

const password = 'Maninfini1manf';
const saltRounds = 10;

bcrypt.hash(password, saltRounds, function(err, hash) {
  if (err) {
    console.error('Error generating hash:', err);
    return;
  }
  console.log('Password:', password);
  console.log('Complete Hash:', hash);
  console.log('Hash length:', hash.length);
});
