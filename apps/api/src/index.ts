import Fastify from "fastify";
import { Kafka } from "kafkajs";
import { EventSchema } from "@eventflow/event-schema";

const fastify = Fastify({ logger: true });

const brokers = (process.env.KAFKA_BROKERS || "127.0.0.1:9092").split(",");
const kafka = new Kafka({
  clientId: "eventflow-api",
  brokers,
});
const producer = kafka.producer();

fastify.post("/events", async (request: any, reply: any) => {
  try {
    const event = EventSchema.parse(request.body);
    
    await producer.send({
      topic: "events",
      messages: [{ key: event.entity_id, value: JSON.stringify(event) }],
    });
    
    reply.code(202).send({ message: "Event accepted", event_id: event.event_id });
  } catch (err) {
    reply.code(400).send({ error: "Invalid event payload", details: err });
  }
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