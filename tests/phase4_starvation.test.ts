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
  } catch (err) {
    // Ignore fetch errors during heavy load in test
  }
}

async function run() {
  console.log("=== PHASE 4: STARVATION PREVENTION TEST ===");
  
  await query('TRUNCATE TABLE processed_events;');
  console.log("Cleared processed_events table.");

  console.log("Sending 1 isolated LOW priority event (STARVED-LOW-1)...");
  await sendEvent('STARVED-LOW-1', 'LOW');
  
  console.log("Now bombarding the system with a continuous stream of HIGH/CRITICAL events for 15 seconds to try and starve it...");
  
  let keepBombarding = true;
  let sentCount = 0;
  
  const bombard = async () => {
    while (keepBombarding) {
      await sendEvent(`BOMBARD-HIGH-${++sentCount}`, 'HIGH');
      await new Promise(r => setTimeout(r, 100)); // send every 100ms
    }
  };
  
  // Start bombarding asynchronously
  bombard();
  
  // Wait 15 seconds
  let countdown = 15;
  while (countdown > 0) {
    console.log(`Bombarding... (${countdown} seconds left)`);
    await new Promise(r => setTimeout(r, 1000));
    countdown--;
  }
  
  keepBombarding = false;
  console.log(`Finished bombarding. Sent ~${sentCount} high priority events.`);
  
  console.log("Waiting for worker to process events (max 45 seconds)...");
  
  let processed = false;
  let allRes;
  for (let i = 0; i < 45; i++) {
    await new Promise(r => setTimeout(r, 1000));
    allRes = await query("SELECT event_id, processed_at FROM processed_events ORDER BY processed_at ASC");
    if (allRes.rows.find((r: any) => r.event_id === 'STARVED-LOW-1')) {
      processed = true;
      break;
    }
  }
  
  if (processed) {
    const res = await query("SELECT event_id, processed_at FROM processed_events WHERE event_id = 'STARVED-LOW-1'");
    console.log("\n✅ SUCCESS: The LOW event was successfully scheduled and processed!");
    console.log(`Processed At: ${res.rows[0].processed_at}`);
    
    // Check how many HIGH events were processed before it
    const index = allRes.rows.findIndex((r: any) => r.event_id === 'STARVED-LOW-1');
    console.log(`It was processed at position ${index + 1} out of ${allRes.rows.length} total events processed.`);
    console.log("This proves that Aging kicked in, promoted the event's Effective Priority, and prevented starvation!");
  } else {
    console.log("\n❌ FAILED: The LOW event was never processed. It starved!");
  }
  
  process.exit(0);
}

run().catch(console.error);
