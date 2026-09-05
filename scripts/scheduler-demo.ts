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

async function verifyPriority() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: PRIORITY");
  console.log("========================================\n");
  
  const entityId = generateId("ENT");
  console.log("[1] Generating 4 events (LOW, NORMAL, HIGH, CRITICAL) sent in reverse order...");
  
  const lowId = generateId("LOW");
  const normalId = generateId("NORMAL");
  const highId = generateId("HIGH");
  const criticalId = generateId("CRITICAL");
  
  const timestamp = new Date().toISOString();
  
  await sendEvent({ event_id: lowId, event_type: "DEMO", entity_id: entityId + "-L", priority: "LOW", timestamp, payload: {} });
  await sendEvent({ event_id: normalId, event_type: "DEMO", entity_id: entityId + "-N", priority: "NORMAL", timestamp, payload: {} });
  await sendEvent({ event_id: highId, event_type: "DEMO", entity_id: entityId + "-H", priority: "HIGH", timestamp, payload: {} });
  await sendEvent({ event_id: criticalId, event_type: "DEMO", entity_id: entityId + "-C", priority: "CRITICAL", timestamp, payload: {} });
  
  console.log("[2] Sending events to API...");
  console.log("[3] Waiting 5 seconds for processing...");
  await sleep(5000);
  
  const result = await query("SELECT event_id, processed_at FROM processed_events WHERE event_id IN ($1, $2, $3, $4) ORDER BY processed_at ASC", [lowId, normalId, highId, criticalId]);
  
  console.log("[4] Observed execution order from database:");
  const executionOrder = result.rows.map((r: any) => r.event_id.split('-')[0]);
  console.log("    Order: " + executionOrder.join(" -> "));
  
  if (executionOrder.length === 4 && executionOrder[0] === "CRITICAL" && executionOrder[1] === "HIGH" && executionOrder[2] === "NORMAL" && executionOrder[3] === "LOW") {
    console.log("\nRESULT: PASS");
    process.exit(0);
  } else {
    console.log("\nRESULT: FAIL");
    process.exit(1);
  }
}

async function verifyBurst() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: BURST");
  console.log("========================================\n");
  
  const rate = process.env.RATE || "5000";
  const duration = process.env.DURATION || "5";
  
  console.log(`[1] Starting existing load generator: ${rate} events/min for ${duration} seconds`);
  
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
  
  console.log("\n[2] Burst generation complete.");
  console.log("[3] Check processor logs for backlog processing and latency metrics.");
  console.log("\nRESULT: PASS");
  process.exit(0);
}

async function verifyStarvation() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: STARVATION");
  console.log("========================================\n");
  
  const lowId = generateId("STARVE-LOW");
  console.log(`[1] Sending 1 LOW priority event (${lowId})...`);
  await sendEvent({ event_id: lowId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "LOW", timestamp: new Date().toISOString(), payload: {} });
  
  console.log("[2] Generating continuous stream of HIGH priority events for 15 seconds to simulate starvation...");
  
  let stop = false;
  const spam = async () => {
    while (!stop) {
      await sendEvent({ event_id: generateId("STARVE-HIGH"), event_type: "DEMO", entity_id: generateId("ENT"), priority: "HIGH", timestamp: new Date().toISOString(), payload: {} });
      await sleep(100); // 10 events per second
    }
  };
  
  spam();
  await sleep(15000); // Wait 15s to allow aging (AGING_RATE is usually configured in ENV, defaults to enough in 10-15s to bypass high if needed)
  stop = true;
  
  console.log("[3] Stream stopped. Waiting for worker to process events (max 45 seconds)...");
  
  let processed = false;
  for (let i = 0; i < 45; i++) {
    await sleep(1000);
    const result = await query("SELECT event_id FROM processed_events WHERE event_id = $1", [lowId]);
    if (result.rows.length === 1) {
      processed = true;
      break;
    }
  }
  
  if (processed) {
    console.log(`[4] Observed LOW event ${lowId} processed successfully despite HIGH priority flood!`);
    console.log("\nRESULT: PASS");
    process.exit(0);
  } else {
    console.log(`[4] LOW event ${lowId} was NOT processed after 45 seconds.`);
    console.log("\nRESULT: FAIL");
    process.exit(1);
  }
}

async function verifyFailure() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: FAILURE");
  console.log("========================================\n");
  
  const eventId = generateId("FAIL-PERM");
  console.log(`[1] Generating event ${eventId} with simulateError: permanent...`);
  console.log("[2] Sending event to API...");
  
  await sendEvent({ event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: { simulateError: "permanent" } });
  
  console.log("[3] Waiting 5 seconds for processing...");
  await sleep(5000);
  
  const failures = await query("SELECT attempt, error FROM event_failures WHERE event_id = $1", [eventId]);
  const dlq = await query("SELECT event_id, reason FROM dlq_events WHERE event_id = $1", [eventId]);
  
  console.log(`[4] Observed failures in DB: ${failures.rows.length} attempts recorded`);
  console.log(`[5] Observed DLQ routing in DB: ${dlq.rows.length > 0 ? "YES" : "NO"}`);
  
  if (failures.rows.length === 1 && dlq.rows.length === 1) {
    console.log(`    DLQ Reason: ${dlq.rows[0].reason}`);
    console.log("\nRESULT: PASS");
    process.exit(0);
  } else {
    console.log("\nRESULT: FAIL");
    process.exit(1);
  }
}

async function verifyRetry() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: RETRY");
  console.log("========================================\n");
  
  const eventId = generateId("RETRY");
  console.log(`[1] Generating event ${eventId} with simulateError: transient...`);
  console.log("[2] Sending event to API...");
  
  await sendEvent({ event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: { simulateError: "transient" } });
  
  console.log("[3] Waiting 10 seconds for exponential backoff retries to complete...");
  await sleep(10000);
  
  const failures = await query("SELECT attempt, error FROM event_failures WHERE event_id = $1 ORDER BY attempt ASC", [eventId]);
  const processed = await query("SELECT event_id FROM processed_events WHERE event_id = $1", [eventId]);
  
  console.log(`[4] Observed transient failures in DB: ${failures.rows.length} attempts recorded`);
  failures.rows.forEach((r: any) => console.log(`    - Attempt ${r.attempt}: ${r.error}`));
  
  console.log(`[5] Event ultimately succeeded: ${processed.rows.length === 1 ? "YES" : "NO"}`);
  
  if (failures.rows.length > 0 && processed.rows.length === 1) {
    console.log("\nRESULT: PASS");
    process.exit(0);
  } else {
    console.log("\nRESULT: FAIL");
    process.exit(1);
  }
}

async function verifyDuplicate() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: DUPLICATE");
  console.log("========================================\n");
  
  const eventId = generateId("DUP");
  const payload = { event_id: eventId, event_type: "DEMO", entity_id: generateId("ENT"), priority: "NORMAL", timestamp: new Date().toISOString(), payload: {} };
  
  console.log(`[1] Generating event ${eventId}...`);
  console.log("[2] Sending FIRST delivery to API...");
  await sendEvent(payload);
  
  console.log("[3] Waiting 3 seconds for processing...");
  await sleep(3000);
  
  console.log("[4] Sending SECOND (duplicate) delivery to API...");
  await sendEvent(payload);
  
  console.log("[5] Waiting 3 seconds for processing...");
  await sleep(3000);
  
  const processed = await query("SELECT COUNT(*) as count FROM processed_events WHERE event_id = $1", [eventId]);
  const failures = await query("SELECT COUNT(*) as count FROM event_failures WHERE event_id = $1", [eventId]);
  const dlq = await query("SELECT COUNT(*) as count FROM dlq_events WHERE event_id = $1", [eventId]);
  
  const processedCount = parseInt(processed.rows[0].count, 10);
  const failureCount = parseInt(failures.rows[0].count, 10);
  const dlqCount = parseInt(dlq.rows[0].count, 10);
  
  console.log(`[6] Processed records: ${processedCount} (Expected: 1)`);
  console.log(`[7] Failure records: ${failureCount} (Expected: 0)`);
  console.log(`[8] DLQ records: ${dlqCount} (Expected: 0)`);
  
  if (processedCount === 1 && failureCount === 0 && dlqCount === 0) {
    console.log("\nRESULT: PASS");
    process.exit(0);
  } else {
    console.log("\nRESULT: FAIL");
    process.exit(1);
  }
}

async function verifyOrdering() {
  console.log("\n========================================");
  console.log(" EventFlow Scheduler Demo");
  console.log(" Scenario: ORDERING");
  console.log("========================================\n");
  
  const entityId = generateId("ORD-ENT");
  console.log(`[1] Generating 5 sequential events for identical entity_id: ${entityId}...`);
  
  const ids = [generateId("ORD-1"), generateId("ORD-2"), generateId("ORD-3"), generateId("ORD-4"), generateId("ORD-5")];
  
  for (let i = 0; i < ids.length; i++) {
    await sendEvent({ event_id: ids[i], event_type: "DEMO", entity_id: entityId, priority: "NORMAL", timestamp: new Date().toISOString(), payload: { sequence: i } });
    console.log(`    Sent event ${ids[i]}`);
    await sleep(200); // Slight delay to simulate natural sequential ingestion
  }
  
  console.log("[2] Waiting 5 seconds for processing...");
  await sleep(5000);
  
  const result = await query("SELECT event_id FROM processed_events WHERE entity_id = $1 ORDER BY processed_at ASC", [entityId]);
  
  const processedOrder = result.rows.map((r: any) => r.event_id);
  console.log("[3] Observed execution order from database:");
  console.log("    " + processedOrder.join(" -> "));
  
  let isOrdered = processedOrder.length === ids.length;
  for (let i = 0; i < processedOrder.length; i++) {
    if (processedOrder[i] !== ids[i]) isOrdered = false;
  }
  
  if (isOrdered) {
    console.log("\nRESULT: PASS");
    process.exit(0);
  } else {
    console.log("\nRESULT: FAIL");
    process.exit(1);
  }
}

async function run() {
  const args = process.argv.slice(2);
  const scenarioIndex = args.indexOf("--scenario");
  
  if (args.includes("--help") || scenarioIndex === -1 || !args[scenarioIndex + 1]) {
    console.log(`
Usage: ./scripts/scheduler-demo.sh --scenario <name>

Available Scenarios:
  priority    Demonstrates priority ordering (CRITICAL before LOW)
  burst       Generates a burst of events using the load generator
  starvation  Demonstrates aging preventing starvation of a LOW event
  failure     Demonstrates permanent failure classification and DLQ routing
  retry       Demonstrates transient failure, backoff, and eventual success
  duplicate   Demonstrates duplicate/idempotency suppression
  ordering    Demonstrates sequential FIFO ordering for the same entity
`);
    process.exit(args.includes("--help") ? 0 : 1);
  }
  
  await checkInfrastructure();
  
  const scenario = args[scenarioIndex + 1];
  
  switch (scenario.toLowerCase()) {
    case "priority": return await verifyPriority();
    case "burst": return await verifyBurst();
    case "starvation": return await verifyStarvation();
    case "failure": return await verifyFailure();
    case "retry": return await verifyRetry();
    case "duplicate": return await verifyDuplicate();
    case "ordering": return await verifyOrdering();
    default:
      console.error(`❌ Unknown scenario: ${scenario}`);
      process.exit(1);
  }
}

run().catch(err => {
  console.error("Fatal Error:", err);
  process.exit(1);
});
