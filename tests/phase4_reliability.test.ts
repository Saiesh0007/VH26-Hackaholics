import { query } from '../packages/db/src/index';

async function sendEvent(event_id: string, priority: string, simulateError?: string) {
  const payload = {
    event_id,
    event_type: 'TEST_EVENT',
    entity_id: 'E-' + event_id,
    priority,
    timestamp: new Date().toISOString(),
    payload: { amount: 100, simulateError }
  };
  
  try {
    await fetch('http://127.0.0.1:3000/events', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (err) {
    console.error("Fetch failed", err);
  }
}

async function checkExists(table: string, event_id: string): Promise<boolean> {
  const res = await query(`SELECT event_id FROM ${table} WHERE event_id = $1`, [event_id]);
  return res.rows.length > 0;
}

async function countFailures(event_id: string): Promise<number> {
  const res = await query(`SELECT COUNT(*) as count FROM event_failures WHERE event_id = $1`, [event_id]);
  return parseInt(res.rows[0].count, 10);
}

async function run() {
  console.log("=== PHASE 4: RELIABILITY LAYER TEST ===");
  
  await query('TRUNCATE TABLE processed_events;');
  await query('TRUNCATE TABLE event_failures;');
  await query('TRUNCATE TABLE dlq_events;');
  console.log("Cleared DB tables.");

  const testId = Date.now().toString();
  const normalId = 'REL-NORMAL-' + testId;
  const dupId = 'REL-DUP-' + testId;
  const transId = 'REL-TRANS-' + testId;
  const permId = 'REL-PERM-' + testId;

  // Scenario 1: Normal event
  console.log("\n[1] Testing Normal Event...");
  await sendEvent(normalId, 'NORMAL');

  // Scenario 2: Duplicate event
  console.log("\n[2] Testing Duplicate Event...");
  await sendEvent(dupId, 'NORMAL');
  await new Promise(r => setTimeout(r, 1000)); // wait
  await sendEvent(dupId, 'NORMAL'); // send again

  // Scenario 3: Transient failure -> retry -> success
  console.log("\n[3] Testing Transient Failure -> Success...");
  await sendEvent(transId, 'NORMAL', 'transient');

  // Scenario 4: Permanent failure -> DLQ
  console.log("\n[4] Testing Permanent Failure -> DLQ...");
  await sendEvent(permId, 'NORMAL', 'permanent');

  console.log("\nWaiting up to 60 seconds for all retries and processing to complete...");
  
  let processed = false;
  for (let i = 0; i < 60; i++) {
    await new Promise(r => setTimeout(r, 1000));
    // check if permanent is in DLQ and transient is in processed
    const permInDlq = await checkExists('dlq_events', permId);
    const transInProcessed = await checkExists('processed_events', transId);
    
    if (permInDlq && transInProcessed) {
      processed = true;
      break;
    }
    if (i % 5 === 0) console.log(`Waiting... ${i}s`);
  }
  
  // give an extra 2 seconds for any trailing DB writes
  await new Promise(r => setTimeout(r, 2000));

  console.log("\n--- TEST RESULTS ---");
  let allPassed = true;

  // Verify 1: Normal
  const normalSuccess = await checkExists('processed_events', normalId);
  console.log(`1. Normal Event: ${normalSuccess ? '✅ SUCCESS' : '❌ FAILED'}`);
  if (!normalSuccess) allPassed = false;

  // Verify 2: Duplicate
  const dupCount = (await query(`SELECT COUNT(*) as c FROM processed_events WHERE event_id = '${dupId}'`)).rows[0].c;
  const dupSuccess = dupCount === '1';
  console.log(`2. Duplicate Event: ${dupSuccess ? '✅ SUCCESS (Only 1 record)' : '❌ FAILED'}`);
  if (!dupSuccess) allPassed = false;

  // Verify 3: Transient
  const transSuccess = await checkExists('processed_events', transId);
  const transFailures = await countFailures(transId);
  const transPass = transSuccess && transFailures > 0;
  console.log(`3. Transient Failure (Success): ${transPass ? '✅ SUCCESS (Failures recorded: ' + transFailures + ')' : '❌ FAILED'}`);
  if (!transPass) allPassed = false;

  // Verify 4: Permanent
  const permSuccess = !(await checkExists('processed_events', permId));
  const permDlq = await checkExists('dlq_events', permId);
  const permFailures = await countFailures(permId);
  const permPass = permSuccess && permDlq && permFailures > 0;
  console.log(`4. Permanent Failure (DLQ): ${permPass ? '✅ SUCCESS (In DLQ)' : '❌ FAILED'}`);
  if (!permPass) allPassed = false;

  if (allPassed) {
    console.log("\n✅ ALL RELIABILITY TESTS PASSED!");
  } else {
    console.log("\n❌ SOME TESTS FAILED!");
  }

  process.exit(allPassed ? 0 : 1);
}

run().catch(console.error);
