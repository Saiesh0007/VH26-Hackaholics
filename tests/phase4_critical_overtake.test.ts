import { query } from '../packages/db/src/index';

async function sendEvent(event_id: string, priority: string) {
  const payload = {
    event_id,
    event_type: 'TEST_EVENT',
    entity_id: 'E1',
    priority,
    timestamp: new Date().toISOString(),
    payload: { amount: 100 }
  };
  
  try {
    await fetch('http://127.0.0.1:3000/events', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (err) {}
}

async function run() {
  console.log("=== PHASE 4: CRITICAL OVERTAKE TEST ===");
  
  await query('TRUNCATE TABLE processed_events;');
  
  console.log("Sending 1 LOW event...");
  await sendEvent('AGED-LOW-1', 'LOW');
  
  console.log("Bombarding with HIGH events for 11 seconds to keep scheduler busy and let LOW age...");
  // Send 40 HIGH events to keep the scheduler busy (processes 3/sec, so ~13 seconds of work)
  for (let i = 0; i < 40; i++) {
    await sendEvent(`BUSY-HIGH-${i}`, 'HIGH');
  }
  
  console.log("Waiting exactly 10 seconds...");
  await new Promise(r => setTimeout(r, 10000));
  
  console.log("10 seconds passed! Now sending 1 FRESH CRITICAL event...");
  await sendEvent('FRESH-CRITICAL-1', 'CRITICAL');
  
  console.log("Waiting for processing to complete...");
  
  let processed = false;
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 1000));
    const allRes = await query("SELECT event_id, processed_at FROM processed_events ORDER BY processed_at ASC");
    if (allRes.rows.find((r: any) => r.event_id === 'FRESH-CRITICAL-1')) {
      processed = true;
      break;
    }
  }
  
  const allRes = await query("SELECT event_id, processed_at FROM processed_events ORDER BY processed_at ASC");
  
  const lowIndex = allRes.rows.findIndex((r: any) => r.event_id === 'AGED-LOW-1');
  const criticalIndex = allRes.rows.findIndex((r: any) => r.event_id === 'FRESH-CRITICAL-1');
  
  console.log(`\nAGED-LOW-1 position: ${lowIndex + 1}`);
  console.log(`FRESH-CRITICAL-1 position: ${criticalIndex + 1}`);
  
  if (lowIndex < criticalIndex) {
    console.log("Result: The AGED LOW event overtook the FRESH CRITICAL event!");
  } else {
    console.log("Result: The FRESH CRITICAL event overtook the AGED LOW event!");
  }

  process.exit(0);
}

run().catch(console.error);
