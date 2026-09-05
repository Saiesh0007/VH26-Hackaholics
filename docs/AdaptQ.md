# AdaptQ (EventFlow) - Features and Functionalities

AdaptQ (internally referred to as EventFlow) is a production-style, high-throughput adaptive event scheduler and processing pipeline for business events. It is conceptually inspired by operating-system scheduling to ensure critical business events are processed reliably and efficiently under varying loads.

## Core Functionalities & Features

### 1. Adaptive Event Scheduling
The core innovation of AdaptQ is its decision-making scheduler. Instead of simply processing events in a First-In-First-Out (FIFO) manner, the scheduler dynamically balances:
- **Priority**: Executes more important events first (e.g., `CRITICAL` > `HIGH` > `NORMAL` > `LOW`).
- **Fairness**: Uses weighted fairness to ensure higher priority events don't monopolize the system, allowing some lower-priority events to pass through.
- **Aging**: Prevents event starvation. The longer an event waits, the higher its "effective priority" becomes until it is scheduled.
- **Worker Capacity**: Dynamically dispatches work based on worker availability.

### 2. Event Ordering Guarantees
- Events associated with the same `entity_id` (e.g., operations on the same Order) are processed sequentially in the order they logically occurred.
- Independent entities are processed concurrently to maximize throughput.

### 3. Reliability and Resiliency
- **Retry Mechanism**: Transient failures are automatically retried with exponential backoff.
- **Dead Letter Queue (DLQ)**: Permanent failures (exceeding max retries) are sent to a DLQ for inspection, debugging, and manual replay.
- **Idempotency**: The system is designed to handle duplicate events safely. If the same `event_id` is processed multiple times, subsequent duplicates are ignored, ensuring exactly-once business effects.

### 4. Burst Handling and Backpressure
- Utilizes **Apache Kafka** as a durable buffer to absorb sudden spikes in traffic (e.g., scaling from 1K to 20K events/minute).
- **Adaptive Worker Scaling**: The system tracks arrival rate, processing rate, and queue depth. If the backlog grows consistently, it scales up the worker pool to catch up without unbounded in-memory queuing.

### 5. Comprehensive Observability (Dashboard)
Includes a real-time dashboard exposing metrics such as:
- Event arrival and processing rates.
- Queue depth and lag.
- Worker count and utilization.
- Priority queue distributions and starvation risks.
- Processing latency and wait times.
- DLQ and Retry counts.

### 6. Event Ingestion API
- Provides a robust API for external systems to submit events.
- Performs schema validation (using Zod) to reject malformed requests immediately.

### 7. Simulation and Demonstration Tools
- Includes built-in CLI shell scripts (`scheduler-demo.sh`) for demonstrating different system scenarios on demand, such as:
  - Priority scheduling behavior.
  - Sudden traffic bursts.
  - Service failures and recoveries.
  - Event starvation prevention.
  - Out-of-order and duplicate event handling.

## Technology Stack Summary
- **Backend**: Node.js, Fastify, TypeScript, Zod.
- **Frontend (Dashboard)**: React, Vite, Tailwind CSS, Recharts.
- **Event Bus**: Apache Kafka (Durable Queue).
- **Database**: PostgreSQL (Business state and event tracking).
- **Infrastructure**: Docker Compose.
