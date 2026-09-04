export enum Priority {
  CRITICAL = "CRITICAL",
  HIGH = "HIGH",
  NORMAL = "NORMAL",
  LOW = "LOW",
}

export enum EventStatus {
  PENDING = "PENDING",
  PROCESSING = "PROCESSING",
  SUCCESS = "SUCCESS",
  FAILED = "FAILED",
  DLQ = "DLQ",
}

export interface EventPayload {
  [key: string]: any;
}

export interface Event {
  event_id: string;
  event_type: string;
  entity_id: string;
  priority: Priority;
  timestamp: string;
  payload: EventPayload;
}