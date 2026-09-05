import { spawn } from 'child_process';
import { query } from '../packages/db/src/index';

const ratePerMin = parseInt(process.env.RATE || "5000", 10);
const durationSec = parseInt(process.env.DURATION || "60", 10);
const concurrency = parseInt(process.env.CONCURRENCY || "1", 10);

async function run() {
  console.log("=== EVENTFLOW BENCHMARK ===");
  console.log(`Target Rate:       ${ratePerMin.toLocaleString()}/min`);
  console.log(`Duration:          ${durationSec}s`);
  console.log(`Worker Concurrency:${concurrency}`);
  console.log("────────────────────────────");

  // Clear DB
  await query('TRUNCATE TABLE processed_events, event_failures, dlq_events RESTART IDENTITY CASCADE;');

  // Start services
  const api = spawn('npm', ['run', 'start', '-w', '@eventflow/api'], {
    env: { ...process.env, SILENT: 'true' }, stdio: 'inherit', shell: true
  });

  const scheduler = spawn('npm', ['run', 'start', '-w', '@eventflow/scheduler'], {
    env: { ...process.env, SILENT: 'true', SCHEDULER_BATCH_SIZE: '1000', SCHEDULER_TICK_MS: '500' }, stdio: 'inherit', shell: true
  });

  const processor = spawn('npm', ['run', 'start', '-w', '@eventflow/processor'], {
    env: { ...process.env, SILENT: 'true', WORKER_CONCURRENCY: concurrency.toString(), FAKE_PROCESSING_DELAY_MS: '10' }, stdio: 'inherit', shell: true
  });

  // wait 5 sec for startup
  await new Promise(r => setTimeout(r, 5000));

  let peakBacklog = 0;
  let polling = true;

  const telemetryInterval = setInterval(async () => {
    try {
      const res = await fetch('http://127.0.0.1:3001/telemetry');
      if (res.ok) {
        const data = await res.json();
        const currentBacklog = (data.queues.CRITICAL || 0) + (data.queues.HIGH || 0) + (data.queues.NORMAL || 0) + (data.queues.LOW || 0);
        if (currentBacklog > peakBacklog) peakBacklog = currentBacklog;
      }
    } catch (e) {
      // Ignore connection errors if server is starting/stopping
    }
  }, 1000);

  console.log("Starting Load Generator...");
  const startTime = Date.now();

  const loadgen = spawn('npx', ['tsx', 'scripts/loadgen.ts'], {
    env: { ...process.env, TARGET_RATE_MIN: ratePerMin.toString(), DURATION_SEC: durationSec.toString() },
    stdio: 'inherit', shell: true
  });

  await new Promise(r => {
    loadgen.on('close', r);
  });

  console.log("Load generation finished. Waiting 10s for backlog to process...");
  await new Promise(r => setTimeout(r, 10000));

  polling = false;
  clearInterval(telemetryInterval);

  // Fetch Final Telemetry
  let finalBacklog = 0;
  try {
    const res = await fetch('http://127.0.0.1:3001/telemetry');
    if (res.ok) {
      const data = await res.json();
      finalBacklog = (data.queues.CRITICAL || 0) + (data.queues.HIGH || 0) + (data.queues.NORMAL || 0) + (data.queues.LOW || 0);
    }
  } catch (e) { }

  let processedCount = 0;
  let failuresCount = 0;
  let dlqCount = 0;
  try {
    const dbRes = await fetch('http://127.0.0.1:3000/telemetry/db');
    if (dbRes.ok) {
      const data = await dbRes.json();
      processedCount = data.processed || 0;
      failuresCount = data.failures || 0;
      dlqCount = data.dlq || 0;
    }
  } catch (e) {
    // Fallback to direct DB query if API telemetry fails
    const result = await query("SELECT COUNT(*) as count FROM processed_events", []);
    processedCount = parseInt(result.rows[0].count, 10);
    const failResult = await query("SELECT COUNT(*) as count FROM event_failures", []);
    failuresCount = parseInt(failResult.rows[0].count, 10);
    const dlqResult = await query("SELECT COUNT(*) as count FROM dlq_events", []);
    dlqCount = parseInt(dlqResult.rows[0].count, 10);
  }

  // Kill services
  api.kill();
  scheduler.kill();
  processor.kill();

  const targetTotal = Math.floor((ratePerMin / 60) * durationSec);
  const ingestPerSec = Math.floor(targetTotal / durationSec);
  const processPerSec = Math.floor(processedCount / durationSec);

  console.log("\nEVENTFLOW BENCHMARK RESULTS (Markdown Table Row)");
  console.log("─────────────────────────────────────────────────────────────────────────────");
  console.log(`| ${ratePerMin / 1000}K/min | ${concurrency} | ${targetTotal} | ${processedCount} | ${ingestPerSec}/s | ${processPerSec}/s | ${peakBacklog} | ${finalBacklog} | ${failuresCount} | ${dlqCount} |`);
  console.log("─────────────────────────────────────────────────────────────────────────────\n");

  process.exit(0);
}

run().catch(console.error);
