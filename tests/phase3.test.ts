import { query } from '../packages/db/src/index';

async function sendEvent(event_id: string, priority: string) {
  const payload = {
    event_id,
    event_type: 'PAYMENT_SUCCESS',
    entity_id: 'ORDER-991',
    priority,
    timestamp: new Date().toISOString(),
    payload: { amount: 100 }
  };
  
  await fetch('http://127.0.0.1:3000/events', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
}

async function run() {
  console.log("Sending 10 events (5 LOW, 3 NORMAL, 1 HIGH, 1 CRITICAL)...");
  
  await Promise.all([
    sendEvent('EVT-LOW-1', 'LOW'),
    sendEvent('EVT-LOW-2', 'LOW'),
    sendEvent('EVT-LOW-3', 'LOW'),
    sendEvent('EVT-LOW-4', 'LOW'),
    sendEvent('EVT-LOW-5', 'LOW'),
    sendEvent('EVT-NORMAL-1', 'NORMAL'),
    sendEvent('EVT-NORMAL-2', 'NORMAL'),
    sendEvent('EVT-NORMAL-3', 'NORMAL'),
    sendEvent('EVT-HIGH-1', 'HIGH'),
    sendEvent('EVT-CRITICAL-1', 'CRITICAL')
  ]);
  
  console.log("All events sent! Waiting 5 seconds for worker to process them...");
  await new Promise(r => setTimeout(r, 5000));
  
  const res = await query('SELECT event_id, processed_at FROM processed_events ORDER BY processed_at ASC');
  console.log("\n--- Absolute Processing Order in PostgreSQL ---");
  res.rows.forEach((row: any, i: number) => {
    console.log(`${i + 1}. ${row.event_id} (Processed at: ${row.processed_at})`);
  });
  console.log("-----------------------------------------------");
  process.exit(0);
}

run().catch(console.error);
