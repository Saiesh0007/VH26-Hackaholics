import { z } from "zod";
import { Priority, EventStatus, Event, EventPayload } from "./types";

export { Priority, EventStatus };
export type { Event, EventPayload };

export const EventSchema = z.object({
  event_id: z.string(),
  event_type: z.string(),
  entity_id: z.string(),
  priority: z.nativeEnum(Priority),
  timestamp: z.string().datetime(),
  payload: z.record(z.any())
});