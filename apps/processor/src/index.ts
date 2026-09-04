import { Kafka } from "kafkajs";
import { query } from "@eventflow/db";
import { Event } from "@eventflow/event-schema";
import * as dotenv from "dotenv";
import * as path from "path";

dotenv.config({ path: path.resolve(__dirname, "../../../.env") });

const brokers = (process.env.KAFKA_BROKERS || "127.0.0.1:9092").split(",");

const kafka = new Kafka({
  clientId: "eventflow-processor",
  brokers,
});

const consumer = kafka.consumer({ groupId: "processor-group" });

async function run() {
  await consumer.connect();
  console.log("Processor consumer connected");

  await consumer.subscribe({ topic: "dispatched-events", fromBeginning: true });

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      if (!message.value) return;
      const eventString = message.value.toString();
      
      try {
        const event = JSON.parse(eventString) as Event;
        console.log(`[Worker] Starting processing for event ${event.event_id}`);
        
        await new Promise(r => setTimeout(r, 500));
        
        console.log(`[Worker] Processing complete for event ${event.event_id}. Saving to database.`);
        
        await query(
          "INSERT INTO processed_events (event_id, entity_id, event_type, result) VALUES ($1, $2, $3, $4)",
          [event.event_id, event.entity_id, event.event_type, "SUCCESS"]
        );
        
        console.log(`[Worker] Event ${event.event_id} fully processed and persisted.`);
      } catch (err) {
        console.error("[Worker] Failed to process event", err);
      }
    },
  });
}

run().catch(console.error);