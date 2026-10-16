const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const appDir = path.join(__dirname, '..', 'app');
const libDir = path.join(appDir, 'lib');

console.log('\x1b[36m%s\x1b[0m', '⚡ Starting Sunvine EPC with Auto Hot-Reload (Vite/Next.js style)...');

const flutter = spawn('flutter', [
  'run',
  '--dart-define=GATEWAY_BASE_URL=http://127.0.0.1:8787'
], {
  cwd: appDir,
  shell: true,
  stdio: ['pipe', 'inherit', 'inherit']
});

let debounceTimer = null;

// Watch the lib directory recursively using native Node.js fs.watch
if (fs.existsSync(libDir)) {
  fs.watch(libDir, { recursive: true }, (eventType, filename) => {
    if (!filename || !filename.endsWith('.dart')) return;

    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      console.log(`\n\x1b[33m⚡ File changed: ${filename} -> Auto Hot Reloading...\x1b[0m`);
      try {
        flutter.stdin.write('r');
      } catch (e) {
        // stream might be closed
      }
    }, 250);
  });
  console.log('\x1b[32m%s\x1b[0m', `✓ Watching ${libDir} for changes (Ctrl+S will instantly auto-reload!)`);
}

// Forward terminal keyboard input (e.g. R for restart, q for quit)
if (process.stdin.isTTY) {
  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (key) => {
    if (key === '\u0003') { // Ctrl+C
      flutter.kill();
      process.exit();
    }
    flutter.stdin.write(key);
  });
}

flutter.on('close', (code) => {
  process.exit(code || 0);
});
