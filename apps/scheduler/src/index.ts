import { Kafka } from "kafkajs";
import { Event, Priority } from "@eventflow/event-schema";
import * as dotenv from "dotenv";
import * as path from "path";

dotenv.config({ path: path.resolve(__dirname, "../../../.env") });

const brokers = (process.env.KAFKA_BROKERS || "127.0.0.1:9092").split(",");

const kafka = new Kafka({
  clientId: "eventflow-scheduler",
  brokers,
});

const consumer = kafka.consumer({ groupId: "scheduler-group" });
const producer = kafka.producer();

const queues: Record<Priority, { event: Event; rawMessage: string; key: Buffer | null }[]> = {
  [Priority.CRITICAL]: [],
  [Priority.HIGH]: [],
  [Priority.NORMAL]: [],
  [Priority.LOW]: [],
};

const BATCH_SIZE = 3;
const TICK_INTERVAL_MS = 1000;

async function dispatchLoop() {
  const toDispatch = [];
  const priorityOrder = [Priority.CRITICAL, Priority.HIGH, Priority.NORMAL, Priority.LOW];

  for (const priority of priorityOrder) {
    while (toDispatch.length < BATCH_SIZE && queues[priority].length > 0) {
      toDispatch.push(queues[priority].shift()!);
    }
    if (toDispatch.length >= BATCH_SIZE) break;
  }

  if (toDispatch.length > 0) {
    console.log(`\n[Scheduler] Tick: Dispatching ${toDispatch.length} events...`);
    const summary = toDispatch.reduce((acc, curr) => {
      acc[curr.event.priority] = (acc[curr.event.priority] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    console.log(`[Scheduler] Decision: ${JSON.stringify(summary)}`);

    const messages = toDispatch.map(item => ({
      key: item.key,
      value: item.rawMessage
    }));

    try {
      await producer.send({
        topic: "dispatched-events",
        messages,
      });
      console.log(`[Scheduler] Successfully dispatched ${messages.length} events to workers.`);
    } catch (err) {
      console.error("[Scheduler] Failed to dispatch events. They are lost in this prototype.", err);
    }
  }
}

async function run() {
  await producer.connect();
  console.log("Scheduler producer connected");

  await consumer.connect();
  console.log("Scheduler consumer connected");

  setInterval(dispatchLoop, TICK_INTERVAL_MS);
  console.log(`Scheduler tick started with interval ${TICK_INTERVAL_MS}ms and batch size ${BATCH_SIZE}`);

  await consumer.subscribe({ topic: "events", fromBeginning: true });

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      if (!message.value) return;
      const eventString = message.value.toString();
      
      try {
        const event = JSON.parse(eventString) as Event;
        console.log(`[Scheduler] Queuing event ${event.event_id} with priority ${event.priority}`);
        
        queues[event.priority].push({
          event,
          rawMessage: eventString,
          key: message.key,
        });
      } catch (err) {
        console.error("Failed to parse or queue event", err);
      }
    },
  });
}

run().catch(console.error);