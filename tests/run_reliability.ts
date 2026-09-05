import { spawn } from 'child_process';
import { query } from '../packages/db/src/index';

async function run() {
  console.log("=== RUNNING RELIABILITY TEST ===");
  
  const api = spawn('npm.cmd', ['run', 'start', '-w', '@eventflow/api'], {
    env: { ...process.env, SILENT: 'true' }, stdio: 'inherit', shell: true
  });
  
  const scheduler = spawn('npm.cmd', ['run', 'start', '-w', '@eventflow/scheduler'], {
    env: { ...process.env, SILENT: 'true' }, stdio: 'inherit', shell: true
  });
  
  const processor = spawn('npm.cmd', ['run', 'start', '-w', '@eventflow/processor'], {
    env: { ...process.env, SILENT: 'true', RETRY_BACKOFF_MS: '100' }, stdio: 'inherit', shell: true
  });

  await new Promise(r => setTimeout(r, 5000));
  
  const test = spawn('npx.cmd', ['tsx', 'tests/phase4_reliability.test.ts'], {
    env: { ...process.env },
    stdio: 'inherit', shell: true
  });
  
  await new Promise(r => {
    test.on('close', r);
  });
  
  api.kill();
  scheduler.kill();
  processor.kill();
  
  process.exit(0);
}

run().catch(console.error);
