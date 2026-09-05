import { useEffect, useState } from "react";
import { Activity, Server, Database, Layers, ArrowRight, Zap, RefreshCw, XCircle, ShieldAlert } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

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

function App() {
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
            backlog: Object.values(newData.scheduler.queues).reduce((a, b) => a + (b as number), 0)
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
  
  // Calculate instantaneous processing rate (approx) by looking at db.processed difference over history
  // Since db is cached every 2s, we just show 0 if no data
  const isHealthy = telemetry !== null;

  return (
    <div className="min-h-screen bg-background text-gray-100 p-6 font-sans">
      {/* Header */}
      <div className="flex justify-between items-center mb-8 border-b border-surface pb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <Activity className="text-primary w-6 h-6" /> EVENTFLOW
          </h1>
          <p className="text-gray-400 text-sm mt-1">Adaptive Event Scheduler Control Room</p>
        </div>
        <div className="flex items-center gap-3 bg-surface px-4 py-2 rounded-lg border border-gray-800">
          <div className={`w-3 h-3 rounded-full ${isHealthy ? 'bg-success animate-pulse' : 'bg-danger'}`}></div>
          <span className="text-sm font-medium text-gray-300 font-mono">
            {isHealthy ? "SYSTEM HEALTHY" : "SYSTEM OFFLINE"}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <MetricCard title="Arrival Rate" value={`${telemetry?.ingestionRate || 0}/sec`} icon={<ArrowRight className="text-blue-400" />} />
        <MetricCard title="Total Processed" value={telemetry?.db.processed || 0} icon={<Zap className="text-success" />} />
        <MetricCard title="Current Backlog" value={totalBacklog} icon={<Layers className="text-warning" />} />
        <MetricCard title="Workers" value="Auto" subtitle="Kafka eachBatch" icon={<Server className="text-purple-400" />} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        {/* Scheduler Queues */}
        <div className="bg-surface rounded-xl border border-gray-800 p-6 col-span-1">
          <h2 className="text-lg font-semibold text-white mb-6 flex items-center gap-2">
            <Layers className="w-5 h-5" /> Priority Queues
          </h2>
          <div className="space-y-6">
            <QueueBar label="CRITICAL" count={telemetry?.scheduler.queues.CRITICAL || 0} color="bg-critical" max={200} />
            <QueueBar label="HIGH" count={telemetry?.scheduler.queues.HIGH || 0} color="bg-high" max={200} />
            <QueueBar label="NORMAL" count={telemetry?.scheduler.queues.NORMAL || 0} color="bg-normal" max={200} />
            <QueueBar label="LOW" count={telemetry?.scheduler.queues.LOW || 0} color="bg-low" max={200} />
          </div>
        </div>

        {/* Throughput Chart */}
        <div className="bg-surface rounded-xl border border-gray-800 p-6 col-span-2">
           <h2 className="text-lg font-semibold text-white mb-6">Throughput & Backlog Trend</h2>
           <div className="h-64">
             <ResponsiveContainer width="100%" height="100%">
                <LineChart data={history}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                  <XAxis dataKey="time" stroke="#666" tick={{fontSize: 12}} />
                  <YAxis stroke="#666" tick={{fontSize: 12}} />
                  <Tooltip contentStyle={{backgroundColor: '#18181b', borderColor: '#333'}} />
                  <Line type="monotone" dataKey="arrival" name="Arrival/sec" stroke="#3b82f6" strokeWidth={2} dot={false} />
                  <Line type="monotone" dataKey="backlog" name="Backlog Depth" stroke="#f59e0b" strokeWidth={2} dot={false} />
                </LineChart>
             </ResponsiveContainer>
           </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Recent Scheduler Decisions */}
        <div className="bg-surface rounded-xl border border-gray-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Recent Scheduler Decisions</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-300">
              <thead className="text-xs text-gray-400 bg-gray-800/50 uppercase">
                <tr>
                  <th className="px-4 py-3 rounded-tl-lg">Event</th>
                  <th className="px-4 py-3">Effective</th>
                  <th className="px-4 py-3">Aging Bonus</th>
                  <th className="px-4 py-3 rounded-tr-lg">Reason</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800/50">
                {(telemetry?.scheduler.decisions || []).slice(0, 8).map((d, i) => (
                  <tr key={i} className="hover:bg-gray-800/30 font-mono">
                    <td className="px-4 py-3">{d.eventId.split("-")[1]?.substring(0,6) || d.eventId}</td>
                    <td className="px-4 py-3 text-white">{d.effectivePriority}</td>
                    <td className="px-4 py-3 text-success">+{d.agingBonus.toFixed(1)}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded text-xs ${d.reason.includes("STARVATION") ? 'bg-warning/20 text-warning' : 'bg-primary/20 text-primary'}`}>
                        {d.reason}
                      </span>
                    </td>
                  </tr>
                ))}
                {(!telemetry?.scheduler.decisions || telemetry.scheduler.decisions.length === 0) && (
                  <tr><td colSpan={4} className="text-center py-8 text-gray-500">No recent decisions</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Reliability Stats */}
        <div className="bg-surface rounded-xl border border-gray-800 p-6">
           <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
             <ShieldAlert className="w-5 h-5" /> Reliability & Failures
           </h2>
           <div className="grid grid-cols-2 gap-4">
              <div className="bg-gray-900/50 p-4 rounded-lg border border-gray-800">
                <div className="flex items-center gap-2 text-warning mb-2">
                  <RefreshCw className="w-4 h-4" />
                  <span className="font-semibold text-sm">TRANSIENT RETRIES</span>
                </div>
                <div className="text-2xl font-mono text-white">{telemetry?.db.failures || 0}</div>
                <div className="text-xs text-gray-500 mt-1">Recorded failure attempts</div>
              </div>
              
              <div className="bg-gray-900/50 p-4 rounded-lg border border-gray-800">
                <div className="flex items-center gap-2 text-danger mb-2">
                  <XCircle className="w-4 h-4" />
                  <span className="font-semibold text-sm">DEAD LETTER QUEUE</span>
                </div>
                <div className="text-2xl font-mono text-white">{telemetry?.db.dlq || 0}</div>
                <div className="text-xs text-gray-500 mt-1">Permanent failures captured</div>
              </div>
           </div>
        </div>
      </div>
    </div>
  );
}

function MetricCard({ title, value, subtitle, icon }: any) {
  return (
    <div className="bg-surface rounded-xl border border-gray-800 p-6 flex flex-col justify-between">
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-gray-400 font-medium text-sm">{title}</h3>
        {icon}
      </div>
      <div>
        <div className="text-3xl font-bold text-white font-mono">{value}</div>
        {subtitle && <div className="text-xs text-gray-500 mt-1">{subtitle}</div>}
      </div>
    </div>
  );
}

function QueueBar({ label, count, color, max }: any) {
  const percentage = Math.min(100, (count / (max || 100)) * 100);
  return (
    <div>
      <div className="flex justify-between text-xs mb-1 font-mono">
        <span className="text-gray-300">{label}</span>
        <span className="text-white">{count}</span>
      </div>
      <div className="w-full bg-gray-800 rounded-full h-2">
        <div className={`${color} h-2 rounded-full transition-all duration-300 ease-out`} style={{ width: `${percentage}%` }}></div>
      </div>
    </div>
  );
}

export default App;
