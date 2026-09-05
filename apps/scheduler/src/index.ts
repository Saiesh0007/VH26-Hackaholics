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

type QueuedItem = {
  event: Event;
  rawMessage: string;
  key: Buffer | null;
  enqueueTimeMs: number;
  basePriority: number;
};

const queues: Record<Priority, QueuedItem[]> = {
  [Priority.CRITICAL]: [],
  [Priority.HIGH]: [],
  [Priority.NORMAL]: [],
  [Priority.LOW]: [],
};

const BATCH_SIZE = parseInt(process.env.SCHEDULER_BATCH_SIZE || "3", 10);
const TICK_INTERVAL_MS = parseInt(process.env.SCHEDULER_TICK_MS || "1000", 10);
const SILENT = process.env.SILENT === "true";

const BASE_PRIORITY_MAP = {
  [Priority.CRITICAL]: 100,
  [Priority.HIGH]: 70,
  [Priority.NORMAL]: 40,
  [Priority.LOW]: 10,
};

const MAX_AGING_BONUS = 10000;
const AGING_RATE_PER_SEC = 10; // 10 points per second

import Fastify from "fastify";
import cors from "@fastify/cors";

const fastify = Fastify({ logger: !SILENT });
// @ts-ignore
fastify.register(cors, { origin: "*" });

const recentDecisions: any[] = [];

async function dispatchLoop() {
  const toDispatch: { item: QueuedItem; effectivePriority: number; agingBonus: number; waitTimeMs: number; reason: string }[] = [];
  
  for (let i = 0; i < BATCH_SIZE; i++) {
    const nowMs = Date.now();
    let bestQueue: Priority | null = null;
    let bestEffective = -1;
    let bestBase = -1;
    let bestEnqueueTime = Infinity;
    let bestAgingBonus = 0;
    let bestWaitMs = 0;

    for (const priority of [Priority.CRITICAL, Priority.HIGH, Priority.NORMAL, Priority.LOW]) {
      const queue = queues[priority];
      if (queue.length === 0) continue;
      
      const head = queue[0];
      const waitTimeMs = Math.max(0, nowMs - head.enqueueTimeMs);
      const waitSeconds = waitTimeMs / 1000;
      const agingBonus = Math.min(MAX_AGING_BONUS, waitSeconds * AGING_RATE_PER_SEC);
      const effective = head.basePriority + agingBonus;
      
      let isBetter = false;
      if (effective > bestEffective) {
        isBetter = true;
      } else if (effective === bestEffective) {
        if (head.basePriority > bestBase) {
          isBetter = true;
        } else if (head.basePriority === bestBase) {
          if (head.enqueueTimeMs < bestEnqueueTime) {
            isBetter = true;
          }
        }
      }
      
      if (isBetter) {
        bestEffective = effective;
        bestBase = head.basePriority;
        bestEnqueueTime = head.enqueueTimeMs;
        bestQueue = priority;
        bestAgingBonus = agingBonus;
        bestWaitMs = waitTimeMs;
      }
    }
    
    if (bestQueue) {
      const item = queues[bestQueue].shift()!;
      let reason = "STRICT_PRIORITY";
      // If aging bonus exceeds the tier difference (e.g. 30 points between tiers)
      // or if it was a LOW event that reached a high priority
      if (bestAgingBonus >= 20 || (item.basePriority === BASE_PRIORITY_MAP[Priority.LOW] && bestEffective > BASE_PRIORITY_MAP[Priority.NORMAL])) {
         reason = "STARVATION_PREVENTION";
      }
      toDispatch.push({ item, effectivePriority: bestEffective, agingBonus: bestAgingBonus, waitTimeMs: bestWaitMs, reason });
    } else {
      break; 
    }
  }

  if (toDispatch.length > 0) {
    if (!SILENT) console.log(`\n[Scheduler] Tick: Dispatching ${toDispatch.length} events...`);
    
    for (const dispatched of toDispatch) {
       recentDecisions.unshift({
         eventId: dispatched.item.event.event_id,
         priority: dispatched.item.event.priority,
         effectivePriority: dispatched.effectivePriority,
         agingBonus: dispatched.agingBonus,
         reason: dispatched.reason,
         timestamp: Date.now()
       });
       if (recentDecisions.length > 20) recentDecisions.pop();
       
       if (!SILENT) {
         console.log(`\n[SCHEDULER]`);
         console.log(`Event: ${dispatched.item.event.event_id}`);
         console.log(`Base Priority: ${dispatched.item.event.priority} (${dispatched.item.basePriority})`);
         console.log(`Wait: ${(dispatched.waitTimeMs / 1000).toFixed(1)}s`);
         console.log(`Aging Bonus: +${dispatched.agingBonus.toFixed(1)}`);
         console.log(`Effective Priority: ${dispatched.effectivePriority.toFixed(1)}`);
         console.log(`Decision: DISPATCH`);
         console.log(`Reason: ${dispatched.reason}`);
       }
    }

    const messages = toDispatch.map(d => ({
      key: d.item.key,
      value: d.item.rawMessage
    }));

    try {
      await producer.send({
        topic: "dispatched-events",
        messages,
      });
      if (!SILENT) console.log(`\n[Scheduler] Successfully dispatched ${messages.length} events to workers.`);
    } catch (err) {
      console.error("[Scheduler] Failed to dispatch events.", err);
    }
  }
}

fastify.get("/telemetry", async () => {
  return {
    queues: {
      CRITICAL: queues[Priority.CRITICAL].length,
      HIGH: queues[Priority.HIGH].length,
      NORMAL: queues[Priority.NORMAL].length,
      LOW: queues[Priority.LOW].length
    },
    decisions: recentDecisions
  };
});

async function run() {
  await producer.connect();
  console.log("Scheduler producer connected");

  await consumer.connect();
  console.log("Scheduler consumer connected");

  setInterval(dispatchLoop, TICK_INTERVAL_MS);
  
  setInterval(() => {
    const totalDepth = Object.values(queues).reduce((sum, q) => sum + q.length, 0);
    if (!SILENT) console.log(`[Metrics] Scheduler Queue Depth: ${totalDepth}`);
  }, 2000);
  
  console.log(`Scheduler tick started with interval ${TICK_INTERVAL_MS}ms and batch size ${BATCH_SIZE}`);

  await consumer.subscribe({ topic: "events", fromBeginning: true });

  await fastify.listen({ port: 3001, host: "0.0.0.0" });
  console.log("Scheduler telemetry API running on port 3001");

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      if (!message.value) return;
      const eventString = message.value.toString();
      
      try {
        const event = JSON.parse(eventString) as Event;
        if (!SILENT) console.log(`[Scheduler] Queuing event ${event.event_id} with priority ${event.priority}`);
        
        queues[event.priority].push({
          event,
          rawMessage: eventString,
          key: message.key,
          enqueueTimeMs: Date.now(),
          basePriority: BASE_PRIORITY_MAP[event.priority],
        });
      } catch (err) {
        console.error("Failed to parse or queue event", err);
      }
    },
  });
}

run().catch(console.error);