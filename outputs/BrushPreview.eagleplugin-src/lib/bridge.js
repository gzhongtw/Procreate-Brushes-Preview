const path = require('path');
const {execFile} = require('child_process');
const binary = path.join(__dirname, '..', 'bin', 'brush-preview');
function run(args) {
  return new Promise((resolve, reject) => execFile(binary, args, {timeout: 30000, maxBuffer: 192 * 1024 * 1024}, (err, stdout, stderr) => {
    if (err) reject(new Error((stderr || err.message).slice(0, 2000))); else resolve(stdout);
  }));
}
exports.inspect = async src => JSON.parse(await run(['--inspect', src]));
exports.thumbnail = async (src,dest) => run(['--thumbnail',src,dest]);
