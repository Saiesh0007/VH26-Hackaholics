import { query } from './packages/db/src/index.ts';

async function run() {
  try {
    await query("INSERT INTO processed_events (event_id, entity_id, event_type, result) VALUES ('test2', 'e1', 't1', 'SUCCESS')");
    await query("INSERT INTO processed_events (event_id, entity_id, event_type, result) VALUES ('test2', 'e1', 't1', 'SUCCESS')");
  } catch (err: any) {
    console.log("ERROR KEYS:", Object.keys(err));
    console.log("ERROR CODE:", err.code);
    console.log("ERROR MESSAGE:", err.message);
    console.log("ERROR JSON:", JSON.stringify(err, Object.getOwnPropertyNames(err)));
  }
  process.exit(0);
}
run();
