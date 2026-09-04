import { createContext, useContext, useEffect, useMemo, useRef, useState, useCallback } from 'react'
import { BrowserRouter, useLocation, Routes, Route, Link, Navigate } from 'react-router-dom'
import { Activity, AlertTriangle, ArrowRight, BarChart3, Box, ChevronRight, Clock3, Database, Gauge, LayoutDashboard, SlidersHorizontal, Server, Settings, Wifi, Zap, TrendingUp } from 'lucide-react'
import { AreaChart, Area, LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

// ─── WebSocket Context ───────────────────────────────────────────────
const WsCtx = createContext(null)

function WsProvider({ children }) {
  const [data, setData] = useState(null)
  const wsRef = useRef(null)

  useEffect(() => {
    function connect() {
      const proto = location.protocol === 'https:' ? 'wss' : 'ws'
      const ws = new WebSocket(`${proto}://${location.host}/ws`)
      wsRef.current = ws
      ws.onmessage = (e) => setData(JSON.parse(e.data))
      ws.onclose = () => setTimeout(connect, 2000)
      ws.onerror = () => ws.close()
    }
    connect()
    return () => wsRef.current?.close()
  }, [])

  return <WsCtx.Provider value={data}>{children}</WsCtx.Provider>
}

function useWs() { return useContext(WsCtx) }

// ─── Shared UI Components ────────────────────────────────────────────
const navAdmin = [
  ['/admin', 'Overview', LayoutDashboard],
  ['/admin/traffic', 'Traffic', Wifi],
  ['/admin/pipeline', 'Pipeline', Activity],
  ['/admin/queues', 'Queues', Database],
  ['/admin/events', 'Events', Clock3],
  ['/admin/decisions', 'Decisions', SlidersHorizontal],
  ['/admin/simulation', 'Simulation', Gauge],
  ['/admin/benchmarks', 'Benchmarks', BarChart3],
  ['/admin/alerts', 'Alerts', AlertTriangle],
  ['/admin/settings', 'Settings', Settings],
]

function Button({ children, secondary = false, onClick, type = 'button', disabled = false }) {
  return (
    <button type={type} onClick={onClick} disabled={disabled}
      className={`inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold transition disabled:opacity-50
      ${secondary ? 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-50' : 'bg-[#0f9d88] text-white hover:bg-[#087f6f]'}`}>
      {children}
    </button>
  )
}

function Shell({ children }) {
  const loc = useLocation()
  const data = useWs()
  const levelName = data ? ['NORMAL', 'ELEVATED', 'CRITICAL', 'EMERGENCY'][data.level] : 'CONNECTING...'
  const levelColor = data ? ['#0f9d88', '#e65100', '#b71c1c', '#880e4f'][data.level] : '#666'

  return (
    <div className="shell flex bg-[#f5f8fc]">
      <aside className="hidden w-64 shrink-0 flex-col border-r border-slate-200 bg-white p-5 lg:flex">
        <Link to="/admin" className="flex items-center gap-3 px-2 text-lg font-bold text-[#102a43]">
          <span className="grid size-8 place-items-center rounded-lg bg-[#0f9d88] text-sm text-white">J</span> JugaadFlow
        </Link>
        <div className="mt-6 rounded-lg px-3 py-2 text-center text-xs font-bold tracking-wide" style={{ background: levelColor + '22', color: levelColor }}>
          {levelName}
        </div>
        <div className="mt-6 flex flex-1 flex-col gap-1">
          {navAdmin.map(([to, label, Icon]) => (
            <Link key={to} to={to}
              className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium ${loc.pathname === to ? 'nav-active' : 'text-slate-500 hover:bg-slate-50'}`}>
              <Icon size={17} />{label}
            </Link>
          ))}
        </div>
        <div className="border-t border-slate-100 pt-4">
          <p className="text-xs text-slate-400">JugaadFlow v1.0</p>
          <p className="text-xs text-slate-400">8 workers · adaptive pipeline</p>
        </div>
      </aside>
      <main className="min-w-0 flex-1">
        <header className="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-5 lg:px-8">
          <span className="mono text-xs uppercase tracking-widest text-slate-400">
            Control room / {loc.pathname.split('/').filter(Boolean).slice(-1)[0] || 'overview'}
          </span>
          <div className="flex items-center gap-3">
            <span className="hidden items-center gap-2 text-xs text-slate-500 sm:flex">
              <span className="size-2 rounded-full" style={{ background: data ? '#0f9d88' : '#ef6a5b' }} />
              {data ? 'Pipeline active' : 'Connecting...'}
            </span>
          </div>
        </header>
        <div className="p-5 lg:p-8">{children}</div>
      </main>
    </div>
  )
}

function PageTitle({ eyebrow, title, desc, action }) {
  return (
    <div className="mb-7 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
      <div>
        <p className="mono text-[11px] uppercase tracking-[.2em] text-[#0f9d88]">{eyebrow}</p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-[#102a43]">{title}</h1>
        {desc && <p className="mt-2 text-sm text-slate-500">{desc}</p>}
      </div>
      {action}
    </div>
  )
}

function Stat({ label, value, sub, critical = false }) {
  return (
    <div className="glass rounded-xl p-5">
      <p className="text-xs font-medium uppercase tracking-wide text-slate-400">{label}</p>
      <p className={`mt-3 text-3xl font-semibold ${critical ? 'critical' : 'text-[#102a43]'}`}>{value}</p>
      <p className="mt-2 text-xs text-slate-500">{sub}</p>
    </div>
  )
}

// ─── Helper ──────────────────────────────────────────────────────────
const BASE_RATE = 3400
const TIER_MAX = { tier1: Infinity, tier2: 5000, tier3: 2000, tier4: 500 }
const LEVEL_NAMES = ['Normal', 'Elevated', 'Critical', 'Emergency']

function sumObj(obj) {
  if (!obj) return 0
  return Object.values(obj).reduce((a, b) => a + b, 0)
}

function tierPressure(queues, tier) {
  if (!queues) return 0
  const depth = queues[tier] || 0
  const max = TIER_MAX[tier]
  if (!isFinite(max)) return Math.min(depth, 100)
  return Math.round((depth / max) * 100)
}

// ─── Admin Overview ──────────────────────────────────────────────────
function Admin() {
  const data = useWs()
  const [history, setHistory] = useState([])

  useEffect(() => {
    if (!data) return
    setHistory(prev => {
      const next = [...prev, sumObj(data.throughput_per_sec)]
      return next.length > 30 ? next.slice(-30) : next
    })
  }, [data])

  if (!data) return <Shell><div className="text-center text-slate-400 py-20">Connecting to pipeline...</div></Shell>

  const traffic = Math.round(data.rate_multiplier * BASE_RATE)
  const evtSec = sumObj(data.throughput_per_sec)
  const queueDepth = (data.queues.tier1 || 0) + (data.queues.tier2 || 0) + (data.queues.tier3 || 0) + (data.queues.tier4 || 0)
  const critLost = data.counters?.shed?.payment || 0
  const deferred = sumObj(data.counters?.deferred)
  const batched = sumObj(data.counters?.batched)
  const shed = sumObj(data.counters?.shed)

  const queues = [
    { priority: 'P0', label: 'Critical (Payment/Order)', pressure: tierPressure(data.queues, 'tier1'), color: '#ef6a5b' },
    { priority: 'P1', label: 'Important (Inventory)', pressure: tierPressure(data.queues, 'tier2'), color: '#e7a93f' },
    { priority: 'P2', label: 'Normal (Clicks)', pressure: tierPressure(data.queues, 'tier3'), color: '#5473a8' },
    { priority: 'P3', label: 'Low (Logs)', pressure: tierPressure(data.queues, 'tier4'), color: '#0f9d88' },
  ]

  const maxBar = Math.max(...history, 1)

  return (
    <Shell>
      <PageTitle eyebrow="Live control room" title="Adaptive pipeline overview"
        desc={`Level: ${LEVEL_NAMES[data.level]} · Updated every second via WebSocket`}
        action={<Button secondary><Activity size={16} /> Live</Button>} />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Stat label="Current traffic" value={`${(traffic / 1000).toFixed(1)}k/min`} sub={`${data.rate_multiplier.toFixed(1)}x multiplier`} />
        <Stat label="Events / sec" value={evtSec} sub={`Processing rate`} />
        <Stat label="Queue depth" value={queueDepth.toLocaleString()} sub={`Across all tiers`} />
        <Stat label="Critical events lost" value={critLost} sub="P0 invariant holding" critical />
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-[1.4fr_1fr]">
        <div className="glass rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-semibold">Traffic & throughput</h2>
              <p className="mt-1 text-sm text-slate-500">Last 30 seconds · live stream</p>
            </div>
            <span className={`rounded-full px-3 py-1 text-xs font-semibold ${data.backpressure ? 'bg-[#fff0ed] text-[#c95043]' : 'bg-[#e6f5f2] text-[#087f6f]'}`}>
              {data.backpressure ? 'Backpressure' : 'Healthy'}
            </span>
          </div>
          <div className="mt-8 flex h-48 items-end gap-1">
            {history.map((v, i) => (
              <div key={i} className="flex-1 rounded-t-sm bg-[#0f9d88] transition-all duration-300"
                style={{ height: `${Math.max((v / maxBar) * 100, 2)}%` }} />
            ))}
          </div>
          <div className="mt-4 flex justify-between text-xs text-slate-400">
            <span>-30s</span><span>-15s</span><span>Now</span>
          </div>
        </div>

        <div className="glass rounded-xl p-6">
          <h2 className="font-semibold">Queue pressure</h2>
          <p className="mt-1 text-sm text-slate-500">Adaptive decisions by priority</p>
          <div className="mt-7 flex flex-col gap-5">
            {queues.map((q) => (
              <div key={q.priority}>
                <div className="mb-2 flex justify-between text-sm">
                  <span className="font-semibold">{q.priority} <span className="font-normal text-slate-400">{q.label}</span></span>
                  <span className="mono text-xs text-slate-500">{q.pressure}%</span>
                </div>
                <div className="h-2 rounded-full bg-slate-100">
                  <div className="h-2 rounded-full transition-all duration-300" style={{ width: `${Math.min(q.pressure, 100)}%`, background: q.color }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-3">
        <Stat label="Deferred events" value={deferred.toLocaleString()} sub="P1/P2 under load" />
        <Stat label="Batched events" value={batched.toLocaleString()} sub="Efficiently grouped" />
        <Stat label="Shed events" value={shed.toLocaleString()} sub="Non-critical only" />
      </div>
    </Shell>
  )
}

// ─── Queue Monitor ───────────────────────────────────────────────────
function QueueMonitor() {
  const data = useWs()
  if (!data) return <Shell><div className="text-center text-slate-400 py-20">Connecting...</div></Shell>

  const tiers = [
    { p: 'P0', name: 'Critical', key: 'tier1', max: '∞', types: ['payment', 'order'], defKey: null },
    { p: 'P1', name: 'Important', key: 'tier2', max: '5,000', types: ['inventory'], defKey: 'deferred_tier2' },
    { p: 'P2', name: 'Normal', key: 'tier3', max: '2,000', types: ['click'], defKey: 'deferred_tier3' },
    { p: 'P3', name: 'Low', key: 'tier4', max: '500', types: ['log'], defKey: null },
  ]

  return (
    <Shell>
      <PageTitle eyebrow="Pipeline health" title="Queue monitor" desc="P0 is protected by design. No critical event is ever shed." />
      <div className="grid gap-5 md:grid-cols-2">
        {tiers.map(t => {
          const depth = data.queues[t.key] || 0
          const pressure = tierPressure(data.queues, t.key)
          const defDepth = t.defKey ? (data.queues[t.defKey] || 0) : 0
          const shedCount = t.types.reduce((sum, type) => sum + (data.counters?.shed?.[type] || 0), 0)
          const deferCount = t.types.reduce((sum, type) => sum + (data.counters?.deferred?.[type] || 0), 0)
          const latKey = 'tier' + (tiers.indexOf(t) + 1)
          const lat = data.latency_ms?.[latKey]

          return (
            <div className="glass rounded-xl p-6" key={t.p}>
              <div className="flex items-center justify-between">
                <div>
                  <span className="mono text-2xl font-bold text-[#102a43]">{t.p}</span>
                  <span className="ml-3 text-sm text-slate-500">{t.name}</span>
                </div>
                <span className="rounded-full bg-[#e6f5f2] px-2.5 py-1 text-xs font-semibold text-[#087f6f]">Active</span>
              </div>
              <div className="mt-6 grid grid-cols-2 gap-5">
                <div><p className="text-xs text-slate-400">Current depth</p><p className="mt-1 text-2xl font-semibold">{depth.toLocaleString()}</p></div>
                <div><p className="text-xs text-slate-400">Pressure</p><p className="mt-1 text-2xl font-semibold">{pressure}%</p></div>
                <div><p className="text-xs text-slate-400">Deferred</p><p className="mt-1 font-semibold">{deferCount.toLocaleString()}</p></div>
                <div><p className="text-xs text-slate-400">Shed</p><p className={`mt-1 font-semibold ${t.p === 'P0' ? 'signal' : ''}`}>{shedCount}</p></div>
              </div>
              <div className="mt-6 border-t border-slate-100 pt-4 text-xs text-slate-500">
                Capacity {t.max} · {t.defKey ? `Deferred queue: ${defDepth}` : 'No deferred queue'} · Latency {lat != null ? `${lat.toFixed(1)}ms` : '—'}
              </div>
            </div>
          )
        })}
      </div>
    </Shell>
  )
}

// ─── Event Stream ────────────────────────────────────────────────────
function EventStream() {
  const data = useWs()
  const events = data?.recent_events || []
  const priorityLabel = { 1: 'P0', 2: 'P1', 3: 'P2', 4: 'P3' }

  return (
    <Shell>
      <PageTitle eyebrow="Observability" title="Event stream" desc="Live events from the adaptive classifier." />
      <div className="glass overflow-auto rounded-xl">
        <table className="w-full min-w-[700px] text-left text-sm">
          <thead className="border-b border-slate-100 text-xs uppercase tracking-wide text-slate-400">
            <tr>
              <th className="px-5 py-4 font-medium">Event ID</th>
              <th className="px-5 py-4 font-medium">Type</th>
              <th className="px-5 py-4 font-medium">Priority</th>
              <th className="px-5 py-4 font-medium">Routed To</th>
              <th className="px-5 py-4 font-medium">Decision</th>
              <th className="px-5 py-4 font-medium">Time</th>
            </tr>
          </thead>
          <tbody>
            {events.map(e => (
              <tr key={e.id} className="border-b border-slate-100 last:border-0">
                <td className="mono px-5 py-4 text-xs">{e.id}</td>
                <td className="px-5 py-4 font-medium">{e.type}</td>
                <td className="px-5 py-4">
                  <span className={`rounded px-2 py-1 text-xs font-bold ${e.priority <= 1 ? 'bg-[#fff0ed] text-[#c95043]' : 'bg-slate-100 text-slate-600'}`}>
                    {priorityLabel[e.priority] || `P${e.priority}`}
                  </span>
                </td>
                <td className="px-5 py-4">{e.queue}</td>
                <td className="px-5 py-4">
                  <span className={`rounded px-2 py-1 text-xs font-bold ${e.decision === 'shed' ? 'bg-[#fff0ed] text-[#c95043]' : e.decision === 'defer' ? 'bg-[#fff8e8] text-[#a36b00]' : 'bg-[#e6f5f2] text-[#087f6f]'}`}>
                    {e.decision}
                  </span>
                </td>
                <td className="mono px-5 py-4 text-xs">{e.time}</td>
              </tr>
            ))}
            {events.length === 0 && (
              <tr><td colSpan={6} className="px-5 py-10 text-center text-slate-400">Waiting for events...</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </Shell>
  )
}

// ─── Decision Explorer ───────────────────────────────────────────────
function Decisions() {
  const data = useWs()
  const decisions = data?.recent_decisions || []

  return (
    <Shell>
      <PageTitle eyebrow="Observability" title="Decision explorer" desc="Strategy changes and routing decisions from the decision engine." />
      <div className="glass overflow-auto rounded-xl">
        <table className="w-full min-w-[800px] text-left text-sm">
          <thead className="border-b border-slate-100 text-xs uppercase tracking-wide text-slate-400">
            <tr>
              <th className="px-5 py-4 font-medium">Timestamp</th>
              <th className="px-5 py-4 font-medium">Level Change</th>
              <th className="px-5 py-4 font-medium">T1 Latency</th>
              <th className="px-5 py-4 font-medium">T1 Queue</th>
              <th className="px-5 py-4 font-medium">Lower Queue</th>
              <th className="px-5 py-4 font-medium">Strategy</th>
              <th className="px-5 py-4 font-medium">Reason</th>
            </tr>
          </thead>
          <tbody>
            {decisions.map((d, i) => (
              <tr key={i} className="border-b border-slate-100 last:border-0">
                <td className="mono px-5 py-4 text-xs">{d.time}</td>
                <td className="px-5 py-4 font-semibold">{d.from_level} → {d.to_level}</td>
                <td className="mono px-5 py-4">{d.t1_latency}</td>
                <td className="mono px-5 py-4">{d.t1_queue}</td>
                <td className="mono px-5 py-4">{d.lower_queue}</td>
                <td className="px-5 py-4">
                  <span className={`rounded px-2 py-1 text-xs font-bold ${d.direction === 'escalate' ? 'bg-[#fff0ed] text-[#c95043]' : 'bg-[#e6f5f2] text-[#087f6f]'}`}>
                    {d.direction === 'escalate' ? 'ESCALATED' : 'DE-ESCALATED'}
                  </span>
                </td>
                <td className="px-5 py-4 text-slate-500">{d.reason}</td>
              </tr>
            ))}
            {decisions.length === 0 && (
              <tr><td colSpan={7} className="px-5 py-10 text-center text-slate-400">No level changes yet...</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </Shell>
  )
}

// ─── Simulation ──────────────────────────────────────────────────────
function Simulation() {
  const data = useWs()
  const [localRate, setLocalRate] = useState(null)
  const [mode, setMode] = useState(null)
  const lastApplied = useRef(0)

  const wsRate = data ? Math.round(data.rate_multiplier * BASE_RATE) : 3400
  const rate = (localRate !== null && Date.now() - lastApplied.current < 3000) ? localRate : wsRate

  useEffect(() => {
    if (mode === null && data) {
      if (wsRate <= 5000) setMode('Normal')
      else if (wsRate <= 25000) setMode('Spike')
      else setMode('Stress')
    }
  }, [data, mode, wsRate])

  const applyRate = useCallback((r) => {
    setLocalRate(r)
    lastApplied.current = Date.now()
    fetch('/api/rate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ events_per_min: r }),
    })
  }, [])

  const currentLevel = data?.level ?? 0
  const extreme = rate > 15000
  const high = rate > 8000

  const decisions = [
    ['P0', 'Stream', 'Critical operations always flow — never shed'],
    ['P1', extreme ? 'Defer' : 'Stream', 'Inventory events — deferred under extreme load'],
    ['P2', extreme ? 'Defer' : high ? 'Batch' : 'Stream', 'Click events — batched or deferred'],
    ['P3', extreme ? 'Shed' : high ? 'Shed' : 'Batch', 'Log events — shed under pressure'],
  ]

  const evtSec = data ? sumObj(data.throughput_per_sec) : 0
  const critLost = data?.counters?.shed?.payment || 0
  const totalProcessed = data ? sumObj(data.counters?.processed) : 0

  return (
    <Shell>
      <PageTitle eyebrow="Traffic lab" title="Pipeline simulator" desc="Adjust traffic rate and observe adaptive routing decisions in real time." />
      <div className="grid gap-6 lg:grid-cols-[360px_1fr]">
        <div className="glass rounded-xl p-6">
          <h2 className="font-semibold">Scenario</h2>
          <div className="mt-4 grid grid-cols-2 gap-2">
            {['Normal', 'Spike', 'Stress', 'Recovery'].map(x => (
              <button onClick={() => {
                setMode(x)
                const rates = { Normal: 3400, Spike: 20000, Stress: 50000, Recovery: 3400 }
                applyRate(rates[x])
              }} key={x}
                className={`rounded-lg border px-3 py-2 text-sm ${mode === x ? 'border-[#0f9d88] bg-[#eef8f6] text-[#087f6f]' : 'border-slate-200 text-slate-500'}`}>
                {x}
              </button>
            ))}
          </div>

          <label className="mt-8 block text-sm font-medium">
            Traffic rate <span className="float-right mono text-[#0f9d88]">{rate.toLocaleString()} / min</span>
          </label>
          <input className="mt-5 w-full accent-[#0f9d88]" type="range" min="1000" max="50000" step="500"
            value={rate} onChange={e => applyRate(+e.target.value)} />
          <div className="mt-2 flex justify-between text-xs text-slate-400"><span>1k</span><span>50k</span></div>

          <p className="mt-4 flex items-center gap-2 text-xs text-[#0f9d88]">
            <span className="size-2 rounded-full bg-[#0f9d88] animate-pulse" /> Pipeline always running
          </p>

          <div className="mt-6 rounded-lg bg-slate-50 p-3">
            <p className="text-xs font-semibold text-slate-600">Current escalation level</p>
            <p className="mt-1 text-lg font-bold" style={{ color: ['#0f9d88', '#e65100', '#b71c1c', '#880e4f'][currentLevel] }}>
              {LEVEL_NAMES[currentLevel]}
            </p>
          </div>
        </div>

        <div className="glass rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-semibold">Decision preview</h2>
              <p className="mt-1 text-sm text-slate-500">{mode || 'Custom'} · {rate.toLocaleString()} events/min</p>
            </div>
            <span className={`rounded-full px-3 py-1 text-xs font-semibold ${data?.backpressure ? 'bg-[#fff0ed] text-[#c95043]' : extreme ? 'bg-[#fff8e8] text-[#a36b00]' : 'bg-[#e6f5f2] text-[#087f6f]'}`}>
              {data?.backpressure ? 'Backpressure' : extreme ? 'High load' : 'Contained'}
            </span>
          </div>

          <div className="mt-8 flex flex-col gap-4">
            {decisions.map(([p, d, r]) => (
              <div className="flex items-center gap-4 rounded-lg border border-slate-100 p-4" key={p}>
                <span className="mono font-bold">{p}</span>
                <ChevronRight size={16} className="text-slate-300" />
                <span className={`rounded px-3 py-1 text-xs font-bold ${d === 'Shed' ? 'bg-[#fff0ed] text-[#c95043]' : d === 'Defer' ? 'bg-[#fff8e8] text-[#a36b00]' : d === 'Batch' ? 'bg-[#e8eef9] text-[#5473a8]' : 'bg-[#e6f5f2] text-[#087f6f]'}`}>
                  {d}
                </span>
                <span className="text-sm text-slate-500">{r}</span>
              </div>
            ))}
          </div>

          <div className="mt-8 grid grid-cols-3 gap-3">
            <Stat label="Throughput" value={`${evtSec}/s`} sub="events processed" />
            <Stat label="P0 lost" value={critLost} sub="Invariant" critical />
            <Stat label="Total processed" value={totalProcessed.toLocaleString()} sub="all time" />
          </div>
        </div>
      </div>
    </Shell>
  )
}

// ─── Traffic ─────────────────────────────────────────────────────────
const TIER_COLORS = ['#ef6a5b', '#e7a93f', '#5473a8', '#0f9d88']
const TIER_LABELS = ['Tier 1 · Critical', 'Tier 2 · Important', 'Tier 3 · Normal', 'Tier 4 · Low']
const TYPE_TIER = { payment: 1, order: 1, inventory: 2, click: 3, log: 4 }
const TYPE_COLORS = { payment: '#ef6a5b', order: '#d94f4f', inventory: '#e7a93f', click: '#5473a8', log: '#0f9d88' }

function Traffic() {
  const data = useWs()
  const [throughputHistory, setThroughputHistory] = useState([])
  const tickRef = useRef(0)

  useEffect(() => {
    if (!data) return
    tickRef.current += 1
    setThroughputHistory(prev => {
      const point = {
        t: tickRef.current,
        tier1: data.throughput_per_sec?.[1] || 0,
        tier2: data.throughput_per_sec?.[2] || 0,
        tier3: data.throughput_per_sec?.[3] || 0,
        tier4: data.throughput_per_sec?.[4] || 0,
      }
      const next = [...prev, point]
      return next.length > 30 ? next.slice(-30) : next
    })
  }, [data])

  if (!data) return <Shell><div className="text-center text-slate-400 py-20">Connecting...</div></Shell>

  const classified = data.classified_per_sec || {}
  const totalClassified = sumObj(classified)
  const incomingRate = Math.round(data.rate_multiplier * BASE_RATE)
  const processedRate = sumObj(data.throughput_per_sec)

  const typeRates = [
    { type: 'payment', label: 'Payment', rate: classified[1] ? Math.round(classified[1] * 0.5) : 0 },
    { type: 'order', label: 'Order', rate: classified[1] ? Math.round(classified[1] * 0.5) : 0 },
    { type: 'inventory', label: 'Inventory', rate: classified[2] || 0 },
    { type: 'click', label: 'Click', rate: classified[3] || 0 },
    { type: 'log', label: 'Log', rate: classified[4] || 0 },
  ]

  const donutData = [
    { name: 'Tier 1', value: classified[1] || 0 },
    { name: 'Tier 2', value: classified[2] || 0 },
    { name: 'Tier 3', value: classified[3] || 0 },
    { name: 'Tier 4', value: classified[4] || 0 },
  ].filter(d => d.value > 0)

  return (
    <Shell>
      <PageTitle eyebrow="Observability" title="Traffic analysis"
        desc={`Incoming: ${incomingRate.toLocaleString()}/min · Classified: ${totalClassified}/s`} />

      <div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {typeRates.map(t => (
          <div className="glass rounded-xl p-4" key={t.type}>
            <div className="flex items-center gap-2">
              <span className="size-2.5 rounded-full" style={{ background: TYPE_COLORS[t.type] }} />
              <span className="text-xs font-medium uppercase tracking-wide text-slate-400">{t.label}</span>
            </div>
            <p className="mt-3 text-2xl font-semibold text-[#102a43]">{t.rate}<span className="text-sm text-slate-400">/s</span></p>
          </div>
        ))}
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-[1.6fr_1fr]">
        <div className="glass rounded-xl p-6">
          <h2 className="font-semibold">Throughput by tier</h2>
          <p className="mt-1 text-sm text-slate-500">Stacked area · last 30 seconds</p>
          <div className="mt-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={throughputHistory}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="t" hide />
                <YAxis width={40} tick={{ fontSize: 11 }} />
                <Tooltip contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px #0001' }} />
                <Area type="monotone" dataKey="tier1" stackId="1" stroke={TIER_COLORS[0]} fill={TIER_COLORS[0]} fillOpacity={0.7} name="Tier 1" />
                <Area type="monotone" dataKey="tier2" stackId="1" stroke={TIER_COLORS[1]} fill={TIER_COLORS[1]} fillOpacity={0.7} name="Tier 2" />
                <Area type="monotone" dataKey="tier3" stackId="1" stroke={TIER_COLORS[2]} fill={TIER_COLORS[2]} fillOpacity={0.7} name="Tier 3" />
                <Area type="monotone" dataKey="tier4" stackId="1" stroke={TIER_COLORS[3]} fill={TIER_COLORS[3]} fillOpacity={0.7} name="Tier 4" />
                <Legend />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="glass rounded-xl p-6">
          <h2 className="font-semibold">Classification split</h2>
          <p className="mt-1 text-sm text-slate-500">Real-time tier distribution</p>
          <div className="mt-2 h-56">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={donutData} cx="50%" cy="50%" innerRadius={55} outerRadius={80} paddingAngle={3} dataKey="value" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                  {donutData.map((_, i) => <Cell key={i} fill={TIER_COLORS[i]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>

          <div className="mt-4 rounded-lg bg-slate-50 p-4">
            <div className="flex items-center justify-between text-sm">
              <span className="text-slate-500">Incoming</span>
              <span className="mono font-semibold">{incomingRate.toLocaleString()}/min</span>
            </div>
            <div className="mt-2 flex items-center justify-between text-sm">
              <span className="text-slate-500">Processed</span>
              <span className="mono font-semibold">{processedRate}/s</span>
            </div>
            <div className="mt-2 flex items-center justify-between text-sm">
              <span className="text-slate-500">Gap</span>
              <span className="mono font-semibold text-[#e7a93f]">{Math.max(0, Math.round(incomingRate / 60) - processedRate)}/s</span>
            </div>
          </div>
        </div>
      </div>
    </Shell>
  )
}

// ─── Pipeline ────────────────────────────────────────────────────────
const LEVEL_STRATEGIES = {
  0: { tier2: 'process', tier3: 'process', tier4: 'process', drain: true },
  1: { tier2: 'process', tier3: 'batch', tier4: 'batch', drain: true },
  2: { tier2: 'batch', tier3: 'defer', tier4: 'shed', drain: false },
  3: { tier2: 'defer', tier3: 'defer', tier4: 'shed', drain: false },
}

function Pipeline() {
  const data = useWs()
  if (!data) return <Shell><div className="text-center text-slate-400 py-20">Connecting...</div></Shell>

  const level = data.level ?? 0
  const strategy = LEVEL_STRATEGIES[level]
  const q = data.queues || {}
  const levelColor = ['#0f9d88', '#e65100', '#b71c1c', '#880e4f'][level]

  const flowNodes = [
    { label: 'Generator', depth: null, sub: `${Math.round(data.rate_multiplier * BASE_RATE).toLocaleString()}/min` },
    { label: 'Input Queue', depth: q.input || 0, sub: `max 10,000` },
    { label: 'Classifier', depth: null, sub: 'Priority tagging' },
  ]

  const tierNodes = [
    { label: 'Tier 1', depth: q.tier1 || 0, max: '∞', action: 'process', color: TIER_COLORS[0] },
    { label: 'Tier 2', depth: q.tier2 || 0, max: '5k', action: strategy.tier2, color: TIER_COLORS[1], deferred: q.deferred_tier2 || 0 },
    { label: 'Tier 3', depth: q.tier3 || 0, max: '2k', action: strategy.tier3, color: TIER_COLORS[2], deferred: q.deferred_tier3 || 0 },
    { label: 'Tier 4', depth: q.tier4 || 0, max: '500', action: strategy.tier4, color: TIER_COLORS[3] },
  ]

  const strategyRows = [
    { tier: 'Tier 1 (P0)', types: 'payment, order', action: 'Always process', defer: '—', shed: 'Never' },
    { tier: 'Tier 2 (P1)', types: 'inventory', action: strategy.tier2, defer: strategy.tier2 === 'defer' ? 'Active' : 'Standby', shed: 'Only if deferred full' },
    { tier: 'Tier 3 (P2)', types: 'click', action: strategy.tier3, defer: strategy.tier3 === 'defer' ? 'Active' : 'Standby', shed: strategy.tier3 === 'shed' ? 'Active' : 'Only if deferred full' },
    { tier: 'Tier 4 (P3)', types: 'log', action: strategy.tier4, defer: '—', shed: strategy.tier4 === 'shed' ? 'Active (sample 5-10%)' : 'On overflow' },
  ]

  const actionBadge = (a) => {
    const cls = a === 'shed' ? 'bg-[#fff0ed] text-[#c95043]' : a === 'defer' ? 'bg-[#fff8e8] text-[#a36b00]' : a === 'batch' ? 'bg-[#e8eef9] text-[#5473a8]' : 'bg-[#e6f5f2] text-[#087f6f]'
    return <span className={`rounded px-2 py-1 text-xs font-bold ${cls}`}>{a}</span>
  }

  return (
    <Shell>
      <PageTitle eyebrow="Architecture" title="Pipeline flow"
        desc="Real-time view of the adaptive pipeline architecture and current strategy." />

      <div className="glass rounded-xl p-6 mb-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-semibold">Data flow</h2>
          <div className="rounded-full px-4 py-1.5 text-sm font-bold" style={{ background: levelColor + '22', color: levelColor }}>
            Level {level} · {LEVEL_NAMES[level]}
          </div>
        </div>

        <div className="flex items-start gap-2 overflow-x-auto pb-4">
          {flowNodes.map((n, i) => (
            <div key={i} className="flex items-center gap-2 shrink-0">
              <div className="rounded-lg border-2 border-slate-200 bg-white px-4 py-3 text-center min-w-[110px]">
                <p className="text-xs font-semibold text-[#102a43]">{n.label}</p>
                {n.depth != null && <p className="mono mt-1 text-lg font-bold text-[#0f9d88]">{n.depth.toLocaleString()}</p>}
                <p className="mt-0.5 text-[10px] text-slate-400">{n.sub}</p>
              </div>
              {i < flowNodes.length - 1 && <ArrowRight size={16} className="text-slate-300 shrink-0" />}
            </div>
          ))}
          <ArrowRight size={16} className="text-slate-300 shrink-0 mt-5" />

          <div className="flex flex-col gap-2 shrink-0">
            {tierNodes.map((t, i) => (
              <div key={i} className="flex items-center gap-2">
                <div className="rounded-lg border-2 px-3 py-2 text-center min-w-[130px]" style={{ borderColor: t.color + '88' }}>
                  <div className="flex items-center justify-between gap-3">
                    <span className="text-xs font-semibold" style={{ color: t.color }}>{t.label}</span>
                    {actionBadge(t.action)}
                  </div>
                  <p className="mono mt-1 text-sm font-bold text-[#102a43]">{t.depth.toLocaleString()} <span className="text-[10px] text-slate-400">/ {t.max}</span></p>
                  {t.deferred != null && <p className="text-[10px] text-slate-400">deferred: {t.deferred}</p>}
                </div>
                <ArrowRight size={14} className="text-slate-300 shrink-0" />
              </div>
            ))}
          </div>

          <div className="flex flex-col items-center justify-center shrink-0">
            <div className="rounded-lg border-2 border-[#0f9d88] bg-[#eef8f6] px-4 py-5 text-center min-w-[100px]">
              <p className="text-xs font-semibold text-[#087f6f]">Workers</p>
              <p className="mono mt-1 text-2xl font-bold text-[#0f9d88]">8</p>
              <p className="text-[10px] text-slate-500">fixed · strict priority</p>
            </div>
          </div>

          <ArrowRight size={16} className="text-slate-300 shrink-0 mt-8" />

          <div className="rounded-lg border-2 border-slate-200 bg-white px-4 py-5 text-center shrink-0 min-w-[80px] mt-3">
            <p className="text-xs font-semibold text-[#102a43]">Sink</p>
            <p className="mono mt-1 text-lg font-bold text-[#0f9d88]">{sumObj(data.counters?.processed).toLocaleString()}</p>
            <p className="text-[10px] text-slate-400">total processed</p>
          </div>
        </div>
      </div>

      <div className="glass overflow-auto rounded-xl">
        <div className="p-5 border-b border-slate-100">
          <h2 className="font-semibold">Current strategy</h2>
          <p className="mt-1 text-sm text-slate-500">Driven by escalation level — changes automatically based on Tier 1 pressure</p>
        </div>
        <table className="w-full min-w-[600px] text-left text-sm">
          <thead className="border-b border-slate-100 text-xs uppercase tracking-wide text-slate-400">
            <tr>
              <th className="px-5 py-3 font-medium">Tier</th>
              <th className="px-5 py-3 font-medium">Event types</th>
              <th className="px-5 py-3 font-medium">Current action</th>
              <th className="px-5 py-3 font-medium">Defer</th>
              <th className="px-5 py-3 font-medium">Shed</th>
            </tr>
          </thead>
          <tbody>
            {strategyRows.map((r, i) => (
              <tr key={i} className="border-b border-slate-100 last:border-0">
                <td className="px-5 py-3 font-semibold">{r.tier}</td>
                <td className="px-5 py-3 text-slate-500">{r.types}</td>
                <td className="px-5 py-3">{actionBadge(r.action.toLowerCase())}</td>
                <td className="px-5 py-3 text-slate-500">{r.defer}</td>
                <td className="px-5 py-3 text-slate-500">{r.shed}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="border-t border-slate-100 px-5 py-3 text-xs text-slate-400">
          Drain deferred: <span className="font-semibold">{strategy.drain ? 'Yes' : 'No'}</span> · Workers pull tier 1 first, always
        </div>
      </div>
    </Shell>
  )
}

// ─── Benchmarks ──────────────────────────────────────────────────────
function Benchmarks() {
  const data = useWs()
  const [latHistory, setLatHistory] = useState([])
  const [tpHistory, setTpHistory] = useState([])
  const tickRef = useRef(0)

  useEffect(() => {
    if (!data) return
    tickRef.current += 1
    const t = tickRef.current
    setLatHistory(prev => {
      const point = {
        t,
        tier1: data.latency_ms?.tier1 ?? null,
        tier2: data.latency_ms?.tier2 ?? null,
        tier3: data.latency_ms?.tier3 ?? null,
        tier4: data.latency_ms?.tier4 ?? null,
      }
      const next = [...prev, point]
      return next.length > 60 ? next.slice(-60) : next
    })
    setTpHistory(prev => {
      const point = {
        t,
        tier1: data.throughput_per_sec?.[1] || 0,
        tier2: data.throughput_per_sec?.[2] || 0,
        tier3: data.throughput_per_sec?.[3] || 0,
        tier4: data.throughput_per_sec?.[4] || 0,
      }
      const next = [...prev, point]
      return next.length > 60 ? next.slice(-60) : next
    })
  }, [data])

  if (!data) return <Shell><div className="text-center text-slate-400 py-20">Connecting...</div></Shell>

  const lat = data.latency_ms || {}
  const counters = data.counters || {}
  const paymentShed = counters.shed?.payment || 0

  const latCards = [
    { tier: 'Tier 1', label: 'Critical', value: lat.tier1, color: TIER_COLORS[0] },
    { tier: 'Tier 2', label: 'Important', value: lat.tier2, color: TIER_COLORS[1] },
    { tier: 'Tier 3', label: 'Normal', value: lat.tier3, color: TIER_COLORS[2] },
    { tier: 'Tier 4', label: 'Low', value: lat.tier4, color: TIER_COLORS[3] },
  ]

  const eventTypes = ['payment', 'order', 'inventory', 'click', 'log']

  return (
    <Shell>
      <PageTitle eyebrow="Performance" title="Benchmarks"
        desc="Latency, throughput, and counters — broken down by priority tier." />

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {latCards.map(c => (
          <div className="glass rounded-xl p-5" key={c.tier}>
            <div className="flex items-center gap-2">
              <span className="size-2.5 rounded-full" style={{ background: c.color }} />
              <span className="text-xs font-medium uppercase tracking-wide text-slate-400">{c.tier} · {c.label}</span>
            </div>
            <p className="mt-3 text-3xl font-semibold text-[#102a43]">
              {c.value != null ? `${c.value.toFixed(1)}` : '—'}<span className="text-sm text-slate-400">ms</span>
            </p>
            <p className="mt-1 text-xs text-slate-500">Avg end-to-end latency</p>
          </div>
        ))}
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <div className="glass rounded-xl p-6">
          <h2 className="font-semibold">Latency over time</h2>
          <p className="mt-1 text-sm text-slate-500">Per-tier · last 60 seconds</p>
          <div className="mt-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={latHistory}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="t" hide />
                <YAxis width={45} tick={{ fontSize: 11 }} unit="ms" />
                <Tooltip contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px #0001' }} />
                <Line type="monotone" dataKey="tier1" stroke={TIER_COLORS[0]} strokeWidth={2} dot={false} name="Tier 1" connectNulls />
                <Line type="monotone" dataKey="tier2" stroke={TIER_COLORS[1]} strokeWidth={2} dot={false} name="Tier 2" connectNulls />
                <Line type="monotone" dataKey="tier3" stroke={TIER_COLORS[2]} strokeWidth={2} dot={false} name="Tier 3" connectNulls />
                <Line type="monotone" dataKey="tier4" stroke={TIER_COLORS[3]} strokeWidth={2} dot={false} name="Tier 4" connectNulls />
                <Legend />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="glass rounded-xl p-6">
          <h2 className="font-semibold">Throughput over time</h2>
          <p className="mt-1 text-sm text-slate-500">Events/sec per tier · last 60 seconds</p>
          <div className="mt-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={tpHistory}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="t" hide />
                <YAxis width={40} tick={{ fontSize: 11 }} />
                <Tooltip contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px #0001' }} />
                <Area type="monotone" dataKey="tier1" stackId="1" stroke={TIER_COLORS[0]} fill={TIER_COLORS[0]} fillOpacity={0.6} name="Tier 1" />
                <Area type="monotone" dataKey="tier2" stackId="1" stroke={TIER_COLORS[1]} fill={TIER_COLORS[1]} fillOpacity={0.6} name="Tier 2" />
                <Area type="monotone" dataKey="tier3" stackId="1" stroke={TIER_COLORS[2]} fill={TIER_COLORS[2]} fillOpacity={0.6} name="Tier 3" />
                <Area type="monotone" dataKey="tier4" stackId="1" stroke={TIER_COLORS[3]} fill={TIER_COLORS[3]} fillOpacity={0.6} name="Tier 4" />
                <Legend />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className="mt-6 glass overflow-auto rounded-xl">
        <div className="p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h2 className="font-semibold">Counters by event type</h2>
            <p className="mt-1 text-sm text-slate-500">Cumulative totals since pipeline start</p>
          </div>
          <div className={`rounded-full px-4 py-1.5 text-xs font-bold ${paymentShed === 0 ? 'bg-[#e6f5f2] text-[#087f6f]' : 'bg-[#fff0ed] text-[#c95043]'}`}>
            Payments shed: {paymentShed} {paymentShed === 0 ? '✓ Invariant holds' : '✗ VIOLATION'}
          </div>
        </div>
        <table className="w-full min-w-[600px] text-left text-sm">
          <thead className="border-b border-slate-100 text-xs uppercase tracking-wide text-slate-400">
            <tr>
              <th className="px-5 py-3 font-medium">Event type</th>
              <th className="px-5 py-3 font-medium">Priority</th>
              <th className="px-5 py-3 font-medium text-right">Processed</th>
              <th className="px-5 py-3 font-medium text-right">Batched</th>
              <th className="px-5 py-3 font-medium text-right">Deferred</th>
              <th className="px-5 py-3 font-medium text-right">Shed</th>
            </tr>
          </thead>
          <tbody>
            {eventTypes.map(t => (
              <tr key={t} className="border-b border-slate-100 last:border-0">
                <td className="px-5 py-3 font-semibold capitalize">{t}</td>
                <td className="px-5 py-3">
                  <span className="rounded px-2 py-0.5 text-xs font-bold" style={{ background: TYPE_COLORS[t] + '22', color: TYPE_COLORS[t] }}>
                    P{TYPE_TIER[t] - 1}
                  </span>
                </td>
                <td className="mono px-5 py-3 text-right">{(counters.processed?.[t] || 0).toLocaleString()}</td>
                <td className="mono px-5 py-3 text-right">{(counters.batched?.[t] || 0).toLocaleString()}</td>
                <td className="mono px-5 py-3 text-right">{(counters.deferred?.[t] || 0).toLocaleString()}</td>
                <td className={`mono px-5 py-3 text-right ${t === 'payment' && (counters.shed?.[t] || 0) > 0 ? 'critical font-bold' : ''}`}>
                  {(counters.shed?.[t] || 0).toLocaleString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  )
}

// ─── Generic placeholder ─────────────────────────────────────────────
function Generic({ title }) {
  return (
    <Shell>
      <PageTitle eyebrow="Control room" title={title} desc="This view is ready for live pipeline metrics." />
      <div className="glass rounded-xl p-10 text-center">
        <Server className="mx-auto text-[#0f9d88]" size={38} />
        <h2 className="mt-4 text-xl font-semibold">Connected to JugaadFlow pipeline</h2>
        <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">
          This page will display detailed {title.toLowerCase()} metrics as the pipeline runs. The WebSocket connection is active.
        </p>
      </div>
    </Shell>
  )
}

// ─── Routes ──────────────────────────────────────────────────────────
function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/admin" replace />} />
      <Route path="/admin" element={<Admin />} />
      <Route path="/admin/queues" element={<QueueMonitor />} />
      <Route path="/admin/events" element={<EventStream />} />
      <Route path="/admin/decisions" element={<Decisions />} />
      <Route path="/admin/simulation" element={<Simulation />} />
      <Route path="/admin/traffic" element={<Traffic />} />
      <Route path="/admin/pipeline" element={<Pipeline />} />
      <Route path="/admin/benchmarks" element={<Benchmarks />} />
      {['alerts', 'settings'].map(x => (
        <Route key={x} path={`/admin/${x}`} element={<Generic title={x[0].toUpperCase() + x.slice(1)} />} />
      ))}
    </Routes>
  )
}

export default function Root() {
  return (
    <BrowserRouter>
      <WsProvider>
        <App />
      </WsProvider>
    </BrowserRouter>
  )
}
