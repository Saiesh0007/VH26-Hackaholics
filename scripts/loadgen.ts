import { query } from '../packages/db/src/index';

const targetRatePerMin = parseInt(process.env.TARGET_RATE_MIN || "1000", 10);
const durationSeconds = parseInt(process.env.DURATION_SEC || "60", 10);
const batchSize = 100; // API POSTs to make concurrently

const targetPerSec = Math.floor(targetRatePerMin / 60);

const priorities = ['CRITICAL', 'HIGH', 'NORMAL', 'LOW'];

async function sendBatch(count: number) {
  const promises = [];
  for (let i = 0; i < count; i++) {
    const priority = priorities[Math.floor(Math.random() * priorities.length)];
    const payload = {
      event_id: `LOAD-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
      event_type: 'BENCHMARK_EVENT',
      entity_id: `E${Math.floor(Math.random() * 1000)}`,
      priority,
      timestamp: new Date().toISOString(),
      payload: { amount: 100 }
    };
    
    promises.push(
      fetch('http://127.0.0.1:3000/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      }).catch(err => {})
    );
  }
  await Promise.all(promises);
}

async function run() {
  console.log(`Starting Load Generator: ${targetRatePerMin} events/min for ${durationSeconds} seconds`);
  console.log(`Target rate per second: ${targetPerSec}`);
  
  let sentCount = 0;
  const startTime = Date.now();
  
  let currentSecond = 0;
  
  const interval = setInterval(async () => {
    currentSecond++;
    
    if (currentSecond > durationSeconds) {
      clearInterval(interval);
      console.log(`Load generator finished. Sent ~${sentCount} events in ${durationSeconds} seconds.`);
      return;
    }
    
    // We need to send `targetPerSec` events this second.
    // To avoid blocking, we send in chunks if the rate is very high.
    let remaining = targetPerSec;
    while (remaining > 0) {
      const chunk = Math.min(remaining, batchSize);
      sendBatch(chunk);
      sentCount += chunk;
      remaining -= chunk;
    }
  }, 1000);
  
  // wait for completion
  await new Promise(r => setTimeout(r, (durationSeconds + 2) * 1000));
}

run().catch(console.error);
