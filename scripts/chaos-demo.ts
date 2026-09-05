import { query } from '../packages/db/src/index';
import { spawn } from 'child_process';
import * as path from 'path';

const API_URL = "http://127.0.0.1:3000/events";

async function sleep(ms: number) {
  return new Promise(r => setTimeout(r, ms));
}

function generateId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
}

async function checkInfrastructure() {
  try {
    const res = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    if (res.status !== 400) {
      throw new Error(`API returned unexpected status: ${res.status}`);
    }
  } catch (err: any) {
    console.error("❌ Infrastructure Check Failed: Ingestion API is not reachable at " + API_URL);
    process.exit(1);
  }

  try {
    await query("SELECT 1", []);
  } catch (err) {
    console.error("❌ Infrastructure Check Failed: PostgreSQL database is not reachable");
    process.exit(1);
  }
}

async function sendEvent(payload: any) {
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  if (res.status !== 202) {
    throw new Error(`Failed to send event: ${res.status} ${await res.text()}`);
  }
}

async function runBaseline() {
  console.log("\n[1] BASELINE");
  console.log("----------------------------------------");
  const eventId = generateId("BASE");
  console.log(`Sending Baseline Event: ${eventId}`);
  await sendEvent({ event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: {} });
  await sleep(2000);
  const result = await query("SELECT event_id FROM processed_events WHERE event_id = $1", [eventId]);
  if (result.rows.length === 1) {
    console.log("Baseline successful: Event processed.");
  } else {
    throw new Error("Baseline failed: Event not processed.");
  }
}

async function runBurst() {
  console.log("\n[2] BURST + BACKPRESSURE");
  console.log("----------------------------------------");
  const rate = process.env.RATE || "5000";
  const duration = process.env.DURATION || "5";
  console.log(`Starting load generator: ${rate} events/min for ${duration} seconds`);
  
  const loadgenPath = path.resolve(__dirname, 'loadgen.ts');
  const child = spawn("npx", ["tsx", loadgenPath], {
    env: { ...process.env, TARGET_RATE_MIN: rate, DURATION_SEC: duration },
    stdio: 'inherit',
    shell: true
  });
  
  await new Promise((resolve, reject) => {
    child.on('close', resolve);
    child.on('error', reject);
  });
  console.log("Burst generation complete.");
}

async function runPriority() {
  console.log("\n[3] PRIORITY");
  console.log("----------------------------------------");
  const entityId = generateId("ENT-PRIO");
  console.log("Generating 4 events (LOW, NORMAL, HIGH, CRITICAL) sent in reverse order under load...");
  
  const lowId = generateId("LOW");
  const normalId = generateId("NORMAL");
  const highId = generateId("HIGH");
  const criticalId = generateId("CRITICAL");
  
  const timestamp = new Date().toISOString();
  
  await sendEvent({ event_id: lowId, event_type: "DEMO", entity_id: entityId + "-L", priority: "LOW", timestamp, payload: {} });
  await sendEvent({ event_id: normalId, event_type: "DEMO", entity_id: entityId + "-N", priority: "NORMAL", timestamp, payload: {} });
  await sendEvent({ event_id: highId, event_type: "DEMO", entity_id: entityId + "-H", priority: "HIGH", timestamp, payload: {} });
  await sendEvent({ event_id: criticalId, event_type: "DEMO", entity_id: entityId + "-C", priority: "CRITICAL", timestamp, payload: {} });
  
  console.log("Waiting for processing (up to 60s due to burst backlog)...");
  for (let i = 0; i < 60; i++) {
    const res = await query("SELECT count(*) as count FROM processed_events WHERE event_id IN ($1, $2, $3, $4)", [lowId, normalId, highId, criticalId]);
    if (parseInt(res.rows[0].count) === 4) break;
    await sleep(1000);
  }
  
  const result = await query("SELECT event_id, processed_at FROM processed_events WHERE event_id IN ($1, $2, $3, $4) ORDER BY processed_at ASC", [lowId, normalId, highId, criticalId]);
  const executionOrder = result.rows.map((r: any) => r.event_id.split('-')[0]);
  console.log("Observed execution order from database:");
  console.log("    Order: " + executionOrder.join(" -> "));
}

async function runStarvation() {
  console.log("\n[4] STARVATION PREVENTION");
  console.log("----------------------------------------");
  const lowId = generateId("STARVE-LOW");
  console.log(`Sending 1 LOW priority event (${lowId})...`);
  await sendEvent({ event_id: lowId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "LOW", timestamp: new Date().toISOString(), payload: {} });
  
  console.log("Generating continuous stream of HIGH priority events for 15 seconds to simulate starvation...");
  let stop = false;
  const spam = async () => {
    while (!stop) {
      await sendEvent({ event_id: generateId("STARVE-HIGH"), event_type: "DEMO", entity_id: generateId("ENT"), priority: "HIGH", timestamp: new Date().toISOString(), payload: {} });
      await sleep(100);
    }
  };
  
  spam();
  await sleep(15000);
  stop = true;
  
  console.log("Stream stopped. Waiting for worker to process events (max 120 seconds)...");
  
  let processed = false;
  for (let i = 0; i < 120; i++) {
    await sleep(1000);
    const result = await query("SELECT event_id FROM processed_events WHERE event_id = $1", [lowId]);
    if (result.rows.length === 1) {
      processed = true;
      break;
    }
  }
  
  if (processed) {
    console.log(`Observed LOW event ${lowId} processed successfully despite HIGH priority flood!`);
  } else {
    console.log(`LOW event ${lowId} was NOT processed after 120 seconds.`);
  }
}

async function runTransientFailure() {
  console.log("\n[5] TRANSIENT FAILURE");
  console.log("----------------------------------------");
  const eventId = generateId("RETRY");
  console.log(`Generating event ${eventId} with simulateError: transient...`);
  await sendEvent({ event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: { simulateError: "transient" } });
  
  console.log("Waiting up to 60 seconds for exponential backoff retries to complete amidst load...");
  for (let i = 0; i < 60; i++) {
    const res = await query("SELECT count(*) as count FROM processed_events WHERE event_id = $1", [eventId]);
    if (parseInt(res.rows[0].count) === 1) break;
    await sleep(1000);
  }
  
  const failures = await query("SELECT attempt, error FROM event_failures WHERE event_id = $1 ORDER BY attempt ASC", [eventId]);
  const processed = await query("SELECT event_id FROM processed_events WHERE event_id = $1", [eventId]);
  
  console.log(`Observed transient failures in DB: ${failures.rows.length} attempts recorded`);
  failures.rows.forEach((r: any) => console.log(`    - Attempt ${r.attempt}: ${r.error}`));
  console.log(`Event ultimately succeeded: ${processed.rows.length === 1 ? "YES" : "NO"}`);
}

async function runPermanentFailure() {
  console.log("\n[6] PERMANENT FAILURE");
  console.log("----------------------------------------");
  const eventId = generateId("FAIL-PERM");
  console.log(`Generating event ${eventId} with simulateError: permanent...`);
  await sendEvent({ event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: { simulateError: "permanent" } });
  
  console.log("Waiting up to 60 seconds for processing amidst load...");
  for (let i = 0; i < 60; i++) {
    const res = await query("SELECT count(*) as count FROM dlq_events WHERE event_id = $1", [eventId]);
    if (parseInt(res.rows[0].count) === 1) break;
    await sleep(1000);
  }
  
  const failures = await query("SELECT attempt, error FROM event_failures WHERE event_id = $1", [eventId]);
  const dlq = await query("SELECT event_id, reason FROM dlq_events WHERE event_id = $1", [eventId]);
  
  console.log(`Observed failures in DB: ${failures.rows.length} attempts recorded`);
  console.log(`Observed DLQ routing in DB: ${dlq.rows.length > 0 ? "YES" : "NO"}`);
  if (dlq.rows.length > 0) {
    console.log(`    DLQ Reason: ${dlq.rows[0].reason}`);
  }
}

async function runDuplicate() {
  console.log("\n[7] DUPLICATE");
  console.log("----------------------------------------");
  const eventId = generateId("DUP");
  const payload = { event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: {} };
  
  console.log(`Generating event ${eventId}...`);
  console.log("Sending FIRST delivery to API...");
  await sendEvent(payload);
  
  console.log("Waiting for FIRST delivery processing (up to 60s)...");
  for (let i = 0; i < 60; i++) {
    const res = await query("SELECT count(*) as count FROM processed_events WHERE event_id = $1", [eventId]);
    if (parseInt(res.rows[0].count) === 1) break;
    await sleep(1000);
  }
  
  console.log("Sending SECOND (duplicate) delivery to API...");
  await sendEvent(payload);
  
  console.log("Waiting 3 seconds to ensure duplicate is rejected...");
  await sleep(3000);
  
  const processed = await query("SELECT COUNT(*) as count FROM processed_events WHERE event_id = $1", [eventId]);
  const failures = await query("SELECT COUNT(*) as count FROM event_failures WHERE event_id = $1", [eventId]);
  const dlq = await query("SELECT COUNT(*) as count FROM dlq_events WHERE event_id = $1", [eventId]);
  
  const processedCount = parseInt(processed.rows[0].count, 10);
  const failureCount = parseInt(failures.rows[0].count, 10);
  const dlqCount = parseInt(dlq.rows[0].count, 10);
  
  console.log(`Processed records: ${processedCount} (Expected: 1)`);
  console.log(`Failure records: ${failureCount} (Expected: 0)`);
  console.log(`DLQ records: ${dlqCount} (Expected: 0)`);
}

async function runOrdering() {
  console.log("\n[8] FIFO ORDERING");
  console.log("----------------------------------------");
  const entityId = generateId("ORD-ENT");
  console.log(`Generating 5 sequential events for identical entity_id: ${entityId}...`);
  
  const ids = [generateId("ORD-1"), generateId("ORD-2"), generateId("ORD-3"), generateId("ORD-4"), generateId("ORD-5")];
  
  for (let i = 0; i < ids.length; i++) {
    await sendEvent({ event_id: ids[i], event_type: "DEMO", entity_id: entityId, priority: "NORMAL", timestamp: new Date().toISOString(), payload: { sequence: i } });
    console.log(`    Sent event ${ids[i]}`);
    await sleep(200);
  }
  
  console.log("Waiting for processing (up to 60s due to burst backlog)...");
  for (let i = 0; i < 60; i++) {
    const res = await query("SELECT count(*) as count FROM processed_events WHERE entity_id = $1", [entityId]);
    if (parseInt(res.rows[0].count) === 5) break;
    await sleep(1000);
  }
  
  const result = await query("SELECT event_id FROM processed_events WHERE entity_id = $1 ORDER BY processed_at ASC", [entityId]);
  
  const processedOrder = result.rows.map((r: any) => r.event_id);
  console.log("Observed execution order from database:");
  console.log("    " + processedOrder.join(" -> "));
}

async function runFinalSystemState() {
  console.log("\n[9] FINAL SYSTEM STATE");
  console.log("----------------------------------------");
  
  const processed = await query("SELECT COUNT(*) as count FROM processed_events", []);
  const failures = await query("SELECT COUNT(*) as count FROM event_failures", []);
  const dlq = await query("SELECT COUNT(*) as count FROM dlq_events", []);
  
  console.log(`Events Processed Total: ${processed.rows[0].count}`);
  console.log(`Total Failure Attempts: ${failures.rows[0].count}`);
  console.log(`Total DLQ Events: ${dlq.rows[0].count}`);
}

async function runChaos() {
  console.log("========================================");
  console.log(" EVENTFLOW INTEGRATED CHAOS DEMO");
  console.log("========================================");
  
  await checkInfrastructure();
  
  try {
    await runBaseline();
    await runBurst();
    await runPriority();
    await runStarvation();
    await runTransientFailure();
    await runPermanentFailure();
    await runDuplicate();
    await runOrdering();
    await runFinalSystemState();
    
    console.log("\n========================================");
    console.log(" CHAOS DEMO COMPLETED");
    console.log("========================================");
    process.exit(0);
  } catch (err) {
    console.error("\n❌ CHAOS DEMO FAILED");
    console.error(err);
    process.exit(1);
  }
}

runChaos().catch(err => {
  console.error("Fatal Error:", err);
  process.exit(1);
});
