import { Kafka } from "kafkajs";
import { query } from "@eventflow/db";
import { Event } from "@eventflow/event-schema";
import * as dotenv from "dotenv";
import * as path from "path";

// Reliability Layer
import { ErrorClassification, ReliabilityConfig } from "./reliability/types";
import { ErrorClassifier } from "./reliability/classifier";
import { RetryPolicy } from "./reliability/retry-policy";
import { Backoff } from "./reliability/backoff";

dotenv.config({ path: path.resolve(__dirname, "../../../.env") });

const brokers = (process.env.KAFKA_BROKERS || "127.0.0.1:9092").split(",");

const kafka = new Kafka({
  clientId: "eventflow-processor",
  brokers,
});

const consumer = kafka.consumer({ groupId: "processor-group" });

const WORKER_CONCURRENCY = parseInt(process.env.WORKER_CONCURRENCY || "1", 10);
const SILENT = process.env.SILENT === "true";
const FAKE_PROCESSING_DELAY_MS = parseInt(process.env.FAKE_PROCESSING_DELAY_MS || "50", 10);

// Reliability configuration
const reliabilityConfig: ReliabilityConfig = {
  maxRetries: parseInt(process.env.MAX_RETRY_ATTEMPTS || "3", 10),
  baseDelayMs: parseInt(process.env.RETRY_BASE_DELAY_MS || "1000", 10),
  maxDelayMs: parseInt(process.env.RETRY_MAX_DELAY_MS || "30000", 10),
};

const retryPolicy = new RetryPolicy(reliabilityConfig);

let processedCount = 0;
setInterval(() => {
  console.log(`[Metrics] Processing Rate: ${processedCount} events/sec`);
  processedCount = 0;
}, 1000);

async function run() {
  await consumer.connect();
  console.log("Processor consumer connected");

  await consumer.subscribe({ topic: "dispatched-events", fromBeginning: true });

  console.log(`Processor started with CONCURRENCY=${WORKER_CONCURRENCY} and DELAY=${FAKE_PROCESSING_DELAY_MS}ms`);
  console.log(`Reliability Config: MaxRetries=${reliabilityConfig.maxRetries}, BaseDelay=${reliabilityConfig.baseDelayMs}ms`);

  await consumer.run({
    partitionsConsumedConcurrently: 1, // Currently 1 partition
    eachBatch: async ({ batch, resolveOffset, heartbeat }) => {
      const messages = batch.messages;
      
      for (let i = 0; i < messages.length; i += WORKER_CONCURRENCY) {
        const chunk = messages.slice(i, i + WORKER_CONCURRENCY);
        
        await Promise.all(chunk.map(async (message) => {
          if (!message.value) return;
          const eventString = message.value.toString();
          
          let parsedEvent: Event | null = null;
          try {
            parsedEvent = JSON.parse(eventString) as Event;
          } catch (err) {
            console.error("[Worker] Invalid JSON in event payload", err);
            resolveOffset(message.offset);
            return;
          }

          const event = parsedEvent;
          let attempt = 1;
          let success = false;

          while (!success) {
            try {
              if (!SILENT && attempt > 1) {
                console.log(`[Worker] Starting processing for event ${event.event_id} (Attempt ${attempt}/${reliabilityConfig.maxRetries + 1})`);
              }
              
              if (FAKE_PROCESSING_DELAY_MS > 0) {
                await new Promise(r => setTimeout(r, FAKE_PROCESSING_DELAY_MS));
              }

              // Simulate errors based on payload for testing (e.g. simulateError: 'transient')
              if (event.payload?.simulateError === 'transient' && attempt <= retryPolicy.getMaxRetries()) {
                  throw new Error("Simulated transient error");
              }
              if (event.payload?.simulateError === 'permanent') {
                  const err: any = new Error("Simulated permanent business error");
                  err.isPermanent = true;
                  throw err;
              }
              
              await query(
                "INSERT INTO processed_events (event_id, entity_id, event_type, result) VALUES ($1, $2, $3, $4)",
                [event.event_id, event.entity_id, event.event_type, "SUCCESS"]
              );
              
              if (!SILENT) console.log(`[Worker] Event ${event.event_id} fully processed and persisted.`);
              processedCount++;
              success = true;
            } catch (err: any) {
              const classification = ErrorClassifier.classify(err);
              const errorMessage = err.message || 'Unknown error';

              if (classification === ErrorClassification.DUPLICATE) {
                if (!SILENT) console.log(`[Worker] Event ${event.event_id} already processed. Duplicate suppressed.`);
                success = true; // Mark as success to avoid retry/DLQ and proceed normally
                break;
              }

              // Record failure in DB for transparency
              try {
                await query(
                  "INSERT INTO event_failures (event_id, attempt, error) VALUES ($1, $2, $3)",
                  [event.event_id, attempt, `Attempt ${attempt} [${classification}]: ${errorMessage}`]
                );
              } catch (dbErr) {
                console.error("[Worker] Failed to record failure to DB", dbErr);
              }

              if (!SILENT) console.error(`[Worker] Event ${event.event_id} failed. Classification: ${classification}. Attempt: ${attempt}`);

              if (retryPolicy.shouldRetry(classification, attempt)) {
                const backoffMs = Backoff.calculateDelay(attempt, reliabilityConfig.baseDelayMs, reliabilityConfig.maxDelayMs);
                if (!SILENT) console.log(`[Worker] Retry scheduled for ${event.event_id} in ${backoffMs}ms...`);
                await Backoff.wait(backoffMs);
                attempt++;
              } else {
                if (!SILENT) console.error(`[Worker] Event ${event.event_id} routing to DLQ (Reason: ${classification})`);
                try {
                  await query(
                    "INSERT INTO dlq_events (event_id, event_type, entity_id, payload, reason) VALUES ($1, $2, $3, $4, $5)",
                    [event.event_id, event.event_type, event.entity_id, JSON.stringify(event.payload), `Failed after ${attempt} attempts. Reason: ${classification}. Message: ${errorMessage}`]
                  );
                } catch (dlqErr) {
                  console.error("[Worker] Failed to insert into DLQ", dlqErr);
                }
                break; // Exit retry loop, DLQ routed.
              }
            }
          }

          resolveOffset(message.offset);
        }));
        
        await heartbeat();
      }
    },
  });
}

run().catch(console.error);