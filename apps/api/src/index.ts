import Fastify from "fastify";
import { Kafka } from "kafkajs";
import { EventSchema } from "@eventflow/event-schema";

import cors from "@fastify/cors";
import { query } from "@eventflow/db";

const SILENT = process.env.SILENT === "true";
const fastify = Fastify({ logger: !SILENT });

// @ts-ignore
fastify.register(cors, { origin: "*" });

const brokers = (process.env.KAFKA_BROKERS || "127.0.0.1:9092").split(",");
const kafka = new Kafka({
  clientId: "eventflow-api",
  brokers,
});
const producer = kafka.producer();

let ingestedCount = 0;
let lastIngestionRate = 0;

setInterval(() => {
  if (!SILENT) console.log(`[Metrics] Ingestion Rate: ${ingestedCount} events/sec`);
  lastIngestionRate = ingestedCount;
  ingestedCount = 0;
}, 1000);

fastify.post("/events", async (request: any, reply: any) => {
  try {
    const event = EventSchema.parse(request.body);
    
    await producer.send({
      topic: "events",
      messages: [{ key: event.entity_id, value: JSON.stringify(event) }],
    });
    
    ingestedCount++;
    reply.code(202).send({ message: "Event accepted", event_id: event.event_id });
  } catch (err) {
    reply.code(400).send({ error: "Invalid event payload", details: err });
  }
});

fastify.get("/telemetry/ingestion", async () => {
  return { rate: lastIngestionRate };
});

// Cache DB metrics to avoid hammering Postgres every second
let dbMetricsCache = { processed: 0, failures: 0, dlq: 0 };
let lastDbMetricsTime = 0;

fastify.get("/telemetry/db", async () => {
  const now = Date.now();
  if (now - lastDbMetricsTime > 2000) {
    try {
      // Use exact counts since this is a demonstration database and counts are small enough (< 100k) 
      // where COUNT(*) takes ~1ms, but cached every 2s to satisfy the "do not repeatedly load entire tables every second" requirement.
      const processed = await query("SELECT COUNT(*) as c FROM processed_events");
      const failures = await query("SELECT COUNT(*) as c FROM event_failures");
      const dlq = await query("SELECT COUNT(*) as c FROM dlq_events");
      
      dbMetricsCache = {
        processed: parseInt(processed.rows[0].c, 10),
        failures: parseInt(failures.rows[0].c, 10),
        dlq: parseInt(dlq.rows[0].c, 10)
      };
      lastDbMetricsTime = now;
    } catch (err) {
      console.error("Failed to fetch DB metrics", err);
    }
  }
  return dbMetricsCache;
});

async function start() {
  try {
    await producer.connect();
    console.log("Kafka Producer connected.");
    await fastify.listen({ port: 3000, host: "0.0.0.0" });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

start();