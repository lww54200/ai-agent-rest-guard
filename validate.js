const fs = require('fs');
require('./src/index.js');
const result = JSON.parse(fs.readFileSync('run-result.json','utf8'));
const sample = JSON.parse(fs.readFileSync('examples/sample.json','utf8'));
if (result.status !== 'ready_for_review') throw new Error('bad status');
if (!result.safety?.noSecrets || !result.safety?.noWalletSigning || !result.safety?.noPayoutChange) throw new Error('missing safety guard');
if (!sample || typeof sample !== 'object') throw new Error('missing sample');
console.log('validation ok:', result.repo);
