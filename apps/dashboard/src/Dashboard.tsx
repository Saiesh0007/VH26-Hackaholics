import { useEffect, useState } from "react";
import { Server, Layers, ArrowRight, Zap, RefreshCw, XCircle } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

type TelemetryData = {
  ingestionRate: number;
  db: {
    processed: number;
    failures: number;
    dlq: number;
  };
  scheduler: {
    queues: {
      CRITICAL: number;
      HIGH: number;
      NORMAL: number;
      LOW: number;
    };
    decisions: any[];
  };
};

const MAX_HISTORY = 30;

function Dashboard() {
  const [telemetry, setTelemetry] = useState<TelemetryData | null>(null);
  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    const fetchTelemetry = async () => {
      try {
        const [ingestionRes, dbRes, schedulerRes] = await Promise.all([
          fetch("http://localhost:3000/telemetry/ingestion").catch(() => null),
          fetch("http://localhost:3000/telemetry/db").catch(() => null),
          fetch("http://localhost:3001/telemetry").catch(() => null)
        ]);

        const ingestion = ingestionRes ? await ingestionRes.json() : { rate: 0 };
        const db = dbRes ? await dbRes.json() : { processed: 0, failures: 0, dlq: 0 };
        const scheduler = schedulerRes ? await schedulerRes.json() : { queues: { CRITICAL: 0, HIGH: 0, NORMAL: 0, LOW: 0 }, decisions: [] };

        const newData = { ingestionRate: ingestion.rate, db, scheduler };
        setTelemetry(newData);

        setHistory(prev => {
          const newHistory = [...prev, {
            time: new Date().toLocaleTimeString(),
            arrival: newData.ingestionRate,
            backlog: Object.values(newData.scheduler.queues).reduce((a: number, b: any) => a + Number(b), 0)
          }];
          if (newHistory.length > MAX_HISTORY) newHistory.shift();
          return newHistory;
        });

      } catch (err) {
        console.error("Failed to fetch telemetry", err);
      }
    };

    fetchTelemetry();
    const interval = setInterval(fetchTelemetry, 1000);
    return () => clearInterval(interval);
  }, []);

  const totalBacklog = telemetry ? Object.values(telemetry.scheduler.queues).reduce((a, b) => a + (b as number), 0) : 0;

  const isHealthy = telemetry !== null;

  return (
    <div className="min-h-screen bg-background text-gray-900 font-sans pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-6">
        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-10 pb-6 border-b border-gray-200 gap-4 animate-slide-up">
          <div className="flex items-center gap-3">
            <div className="bg-black text-white w-10 h-10 rounded-xl flex items-center justify-center shadow-sm">
              <span className="font-bold font-sans text-xl tracking-tighter">Q</span>
            </div>
            <h1 className="text-2xl font-display font-bold tracking-tight text-gray-900">
              AdaptQ
            </h1>
          </div>

          <div className="flex gap-4 items-center">
            <div className="flex items-center gap-2 bg-white px-3 py-1.5 rounded-full border border-gray-200 shadow-sm">
              {isHealthy ? (
                <div className="w-2.5 h-2.5 bg-green-500 rounded-full animate-pulse"></div>
              ) : (
                <div className="w-2.5 h-2.5 bg-red-500 rounded-full"></div>
              )}
              <span className="text-xs font-semibold text-gray-600 tracking-wide uppercase">
                {isHealthy ? "System Healthy" : "System Offline"}
              </span>
            </div>
          </div>
        </div>

        {/* Top Metric Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          <MetricCard title="Arrival Rate" value={`${telemetry?.ingestionRate || 0}/s`} icon={<ArrowRight className="text-blue-600" />} iconBg="bg-blue-100" delay="0ms" />
          <MetricCard title="Total Processed" value={telemetry?.db.processed || 0} icon={<Zap className="text-green-600" />} iconBg="bg-green-100" delay="100ms" />
          <MetricCard title="Current Backlog" value={totalBacklog} icon={<Layers className="text-orange-600" />} iconBg="bg-orange-100" delay="200ms" />
          <MetricCard title="Workers" value="Auto" subtitle="Kafka eachBatch" icon={<Server className="text-purple-600" />} iconBg="bg-purple-100" delay="300ms" />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-10">
          {/* Scheduler Queues */}
          <div className="card-panel p-6 lg:p-8 col-span-1 animate-slide-up" style={{ animationDelay: '400ms' }}>
            <h2 className="text-xl font-display font-bold text-gray-900 mb-6 flex items-center gap-2">
              Priority Queues
            </h2>
            <div className="space-y-6">
              <QueueBar label="CRITICAL" count={telemetry?.scheduler.queues.CRITICAL || 0} color="bg-red-500" max={200} />
              <QueueBar label="HIGH" count={telemetry?.scheduler.queues.HIGH || 0} color="bg-orange-500" max={200} />
              <QueueBar label="NORMAL" count={telemetry?.scheduler.queues.NORMAL || 0} color="bg-blue-500" max={200} />
              <QueueBar label="LOW" count={telemetry?.scheduler.queues.LOW || 0} color="bg-slate-500" max={200} />
            </div>
          </div>

          {/* Throughput Chart */}
          <div className="card-panel p-6 lg:p-8 col-span-1 lg:col-span-2 animate-slide-up" style={{ animationDelay: '500ms' }}>
            <h2 className="text-xl font-display font-bold text-gray-900 mb-6">Throughput & Backlog Trend</h2>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={history} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorArrival" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#2563eb" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="colorBacklog" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#ea580c" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#ea580c" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" vertical={false} />
                  <XAxis dataKey="time" stroke="#9ca3af" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                  <YAxis stroke="#9ca3af" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#ffffff', border: '1px solid #e5e7eb', borderRadius: '12px', color: '#111827', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)' }}
                    itemStyle={{ color: '#111827', fontWeight: 500 }}
                  />
                  <Area type="monotone" dataKey="arrival" name="Arrival/sec" stroke="#2563eb" strokeWidth={3} fillOpacity={1} fill="url(#colorArrival)" />
                  <Area type="monotone" dataKey="backlog" name="Backlog Depth" stroke="#ea580c" strokeWidth={3} fillOpacity={1} fill="url(#colorBacklog)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Recent Scheduler Decisions */}
          <div className="card-panel p-6 lg:p-8 animate-slide-up" style={{ animationDelay: '600ms' }}>
            <h2 className="text-xl font-display font-bold text-gray-900 mb-6">Recent Decisions</h2>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-gray-700">
                <thead className="text-xs text-gray-500 uppercase border-b border-gray-200">
                  <tr>
                    <th className="px-2 py-3 font-semibold">Event</th>
                    <th className="px-2 py-3 font-semibold">Effective</th>
                    <th className="px-2 py-3 font-semibold">Bonus</th>
                    <th className="px-2 py-3 font-semibold">Reason</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {(telemetry?.scheduler.decisions || []).slice(0, 7).map((d, i) => (
                    <tr key={i} className="hover:bg-gray-50 transition-colors">
                      <td className="px-2 py-3 font-mono text-xs text-gray-500">{d.eventId.split("-")[1]?.substring(0, 6) || d.eventId}</td>
                      <td className="px-2 py-3 font-bold text-gray-900">{d.effectivePriority}</td>
                      <td className="px-2 py-3 text-green-600 font-medium">+{d.agingBonus.toFixed(1)}</td>
                      <td className="px-2 py-3">
                        <span className={`px-2 py-1 rounded-md text-[10px] font-bold uppercase tracking-wide ${d.reason.includes("STARVATION") ? 'bg-orange-100 text-orange-700' : 'bg-blue-100 text-blue-700'}`}>
                          {d.reason}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {(!telemetry?.scheduler.decisions || telemetry.scheduler.decisions.length === 0) && (
                    <tr><td colSpan={4} className="text-center py-8 text-gray-400 font-medium">Waiting for scheduler activity...</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Reliability Stats */}
          <div className="card-panel p-6 lg:p-8 flex flex-col animate-slide-up" style={{ animationDelay: '700ms' }}>
            <h2 className="text-xl font-display font-bold text-gray-900 mb-6 flex items-center gap-2">
              Reliability
            </h2>
            <div className="grid grid-cols-2 gap-4 flex-1">
              <div className="bg-orange-50/50 p-6 rounded-2xl border border-orange-100 flex flex-col justify-center items-center text-center">
                <div className="bg-orange-100 p-2 rounded-full mb-3">
                  <RefreshCw className="w-5 h-5 text-orange-600" />
                </div>
                <div className="text-4xl font-display font-bold text-gray-900 mb-1">{telemetry?.db.failures || 0}</div>
                <div className="text-sm font-medium text-gray-500">Transient Retries</div>
              </div>

              <div className="bg-red-50/50 p-6 rounded-2xl border border-red-100 flex flex-col justify-center items-center text-center">
                <div className="bg-red-100 p-2 rounded-full mb-3">
                  <XCircle className="w-5 h-5 text-red-600" />
                </div>
                <div className="text-4xl font-display font-bold text-gray-900 mb-1">{telemetry?.db.dlq || 0}</div>
                <div className="text-sm font-medium text-gray-500">Permanent DLQ</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function MetricCard({ title, value, subtitle, icon, iconBg, delay }: any) {
  return (
    <div className="card-panel card-panel-hover p-6 flex flex-col justify-between animate-slide-up" style={{ animationDelay: delay }}>
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-gray-500 font-semibold text-sm tracking-wide">{title}</h3>
        <div className={`${iconBg} p-2 rounded-xl`}>
          {icon}
        </div>
      </div>
      <div>
        <div className="text-3xl font-display font-bold text-gray-900 tracking-tight">{value}</div>
        {subtitle && <div className="text-xs font-medium text-gray-500 mt-1">{subtitle}</div>}
      </div>
    </div>
  );
}

function QueueBar({ label, count, color, max }: any) {
  const percentage = Math.min(100, (count / (max || 100)) * 100);
  return (
    <div className="group">
      <div className="flex justify-between text-sm mb-2 font-medium">
        <span className="text-gray-600">{label}</span>
        <span className="text-gray-900 font-bold">{count}</span>
      </div>
      <div className="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
        <div
          className={`${color} h-full rounded-full transition-all duration-500 ease-out relative`}
          style={{ width: `${percentage}%` }}
        >
          <div className="absolute inset-0 bg-white/20 animate-pulse-slow" />
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
