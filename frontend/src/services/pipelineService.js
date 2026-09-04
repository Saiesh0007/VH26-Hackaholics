/**
 * Pipeline service — fetches live data from the FastAPI admin endpoints.
 *
 * Falls back to rich mock data if the API is unreachable so the frontend
 * continues to work during standalone demo mode.
 */

import { apiRequest } from './api'

// ─── Mock fallbacks (used when API is down / USE_MOCK=true) ──────────────────

const _mockMetrics = () => ({
  traffic:        14280 + Math.floor(Math.random() * 2000 - 1000),
  events_per_sec: 220  + Math.floor(Math.random() * 30),
  queue_depth:    1750 + Math.floor(Math.random() * 200),
  pressure:       68,
  deferred:       38,
  batched:        76,
  shed:           12,
  critical_lost:  0,
  backpressure:   'Contained',
  timestamp:      new Date().toTimeString().slice(0, 8),
  queues: [
    { priority: 'P0', label: 'Critical', depth: 42,  pressure: 12, deferred: 0,  shed: 0, processing_rate: 42,  p95_latency_ms: 12  },
    { priority: 'P1', label: 'High',     depth: 96,  pressure: 34, deferred: 2,  shed: 0, processing_rate: 96,  p95_latency_ms: 28  },
    { priority: 'P2', label: 'Normal',   depth: 184, pressure: 61, deferred: 10, shed: 1, processing_rate: 184, p95_latency_ms: 65  },
    { priority: 'P3', label: 'Low',      depth: 612, pressure: 82, deferred: 26, shed: 7, processing_rate: 312, p95_latency_ms: 210 },
  ],
})

const _mockEvents = (n = 20) =>
  Array.from({ length: n }, (_, i) => ({
    id:       `evt-${10482 - i}`,
    type:     ['PRODUCT_VIEW','CART_UPDATE','ORDER_CREATED','PAYMENT_CAPTURED'][i % 4],
    priority: ['P3','P1','P0','P0'][i % 4],
    decision: ['BATCH','STREAM','STREAM','STREAM'][i % 4],
    queue:    ['P3','P1','P0','P0'][i % 4],
    pressure: 68 - i * 2,
    worker:   42 + i * 2,
    time:     `12:${31 - i % 30}:0${i % 10}`,
    reason:   i % 3 ? 'Load within threshold' : 'Critical path',
  }))

// ─── Service ─────────────────────────────────────────────────────────────────

export const pipelineService = {
  /**
   * Fetch live pipeline metrics from the API.
   * Returns a metrics object shaped for the admin dashboard.
   */
  metrics: async () => {
    try {
      return await apiRequest('/admin/metrics')
    } catch {
      return _mockMetrics()
    }
  },

  /**
   * Fetch the rolling event log.
   */
  events: async (n = 20) => {
    try {
      const res = await apiRequest(`/admin/events?n=${n}`)
      return res.events
    } catch {
      return _mockEvents(n)
    }
  },

  /**
   * Fetch decision log entries.
   */
  decisions: async (n = 20) => {
    try {
      const res = await apiRequest(`/admin/decisions?n=${n}`)
      return res.decisions
    } catch {
      return _mockEvents(n)
    }
  },

  /**
   * Fetch queue band status.
   */
  queues: async () => {
    try {
      const res = await apiRequest('/admin/queues')
      return res.queues
    } catch {
      return _mockMetrics().queues
    }
  },

  /**
   * Fetch active alerts.
   */
  alerts: async () => {
    try {
      const res = await apiRequest('/admin/alerts')
      return res.alerts
    } catch {
      return [{ id: 'ALT-003', severity: 'info', title: 'P0 invariant holding', message: 'Zero critical events lost.', timestamp: '--' }]
    }
  },

  /**
   * Fetch benchmark results.
   */
  benchmarks: async () => {
    try {
      const res = await apiRequest('/admin/benchmarks')
      return res.benchmarks
    } catch {
      return []
    }
  },
}

// ─── Simulation Service ───────────────────────────────────────────────────────

export const simulationService = {
  /**
   * Get current simulation state.
   */
  state: async () => {
    try {
      return await apiRequest('/admin/simulation')
    } catch {
      return { running: false, mode: 'Normal', rate: 4000, events_ingested: 0, p0_lost: 0, backpressure: 'Contained' }
    }
  },

  /**
   * Start the simulation.
   * @param {{ mode: string, rate: number }} config
   */
  start: async (config) => {
    return apiRequest('/admin/simulation/start', {
      method: 'POST',
      body: JSON.stringify(config),
    })
  },

  /**
   * Stop the simulation.
   */
  stop: async () => {
    return apiRequest('/admin/simulation/stop', { method: 'POST' })
  },

  /**
   * Hot-update the traffic rate (called by slider drag).
   * @param {number} rate - Requests per minute (1000–50000)
   */
  setRate: async (rate) => {
    return apiRequest('/admin/simulation/rate', {
      method: 'PUT',
      body: JSON.stringify({ rate }),
    })
  },
}
