import { ArrowRight, Activity, Zap, ShieldAlert } from "lucide-react";
import { Link } from "react-router-dom";

export default function Landing() {
  return (
    <div className="min-h-screen bg-background font-sans text-gray-900 overflow-x-hidden">
      
      {/* Top Banner */}
      <div className="bg-primary text-white w-full py-2 px-4 flex justify-center items-center text-sm font-medium">
        <span>AdaptQ — Adaptive event pipeline that never drops a critical event</span>
        <Link to="/dashboard" className="ml-2 font-bold underline cursor-pointer hover:text-white/80 transition-colors">
          Open Dashboard →
        </Link>
      </div>

      {/* Navigation */}
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="bg-black text-white w-10 h-10 rounded-xl flex items-center justify-center shadow-sm">
            <span className="font-bold font-sans text-xl tracking-tighter">Q</span>
          </div>
          <h1 className="text-2xl font-display font-bold tracking-tight text-gray-900">
            AdaptQ
          </h1>
        </div>
        
        <Link to="/dashboard">
          <button className="bg-secondary hover:bg-yellow-400 text-black font-bold px-6 py-2.5 rounded-lg shadow-sm transition-colors text-sm">
            Enter Dashboard
          </button>
        </Link>
      </nav>

      {/* Hero Section */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 lg:py-24">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          
          <div className="max-w-xl animate-fade-in">
            <div className="inline-flex items-center gap-2 bg-orange-50 text-orange-600 border border-orange-100 rounded-full px-4 py-1.5 text-xs font-semibold mb-8">
              <span className="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></span>
              Live pipeline • 3,400+ events/min baseline
            </div>
            
            <h2 className="text-6xl md:text-7xl font-display font-extrabold tracking-tight leading-[1.1] mb-6">
              Zero critical<br />events dropped.<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-600 to-yellow-500">
                Ever.
              </span>
            </h2>
            
            <p className="text-lg text-gray-500 mb-8 leading-relaxed font-medium max-w-lg">
              AdaptQ intelligently classifies, routes, and protects your most important revenue-generating events — seamlessly scaling logic when traffic spikes 20×.
            </p>
            
            <div className="flex flex-wrap gap-4">
              <Link to="/dashboard">
                <button className="bg-black hover:bg-gray-800 text-white font-bold px-8 py-3.5 rounded-xl shadow-lg transition-transform hover:-translate-y-0.5">
                  Open Dashboard
                </button>
              </Link>
              <button className="bg-white border-2 border-gray-200 hover:border-gray-300 text-gray-900 font-bold px-8 py-3.5 rounded-xl transition-colors flex items-center gap-2">
                Try Simulator <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>

          <div className="relative animate-slide-up" style={{ animationDelay: '200ms' }}>
            {/* Abstract Grid Graphic */}
            <div className="card-panel p-10 flex justify-center items-center shadow-xl">
              <div className="grid grid-cols-4 gap-3 w-full aspect-square max-w-sm">
                {/* Example colored squares based on the image */}
                <div className="bg-red-600 rounded-lg"></div>
                <div className="bg-purple-600 rounded-lg"></div>
                <div className="bg-purple-500 rounded-lg"></div>
                <div className="bg-transparent rounded-lg"></div>
                
                <div className="bg-yellow-500 rounded-lg"></div>
                <div className="bg-green-700 rounded-lg"></div>
                <div className="bg-transparent rounded-lg"></div>
                <div className="bg-orange-500 rounded-lg"></div>
                
                <div className="bg-orange-500 rounded-lg"></div>
                <div className="bg-red-600 rounded-lg"></div>
                <div className="bg-transparent rounded-lg"></div>
                <div className="bg-blue-600 rounded-lg"></div>
                
                <div className="bg-blue-600 rounded-lg"></div>
                <div className="bg-yellow-500 rounded-lg"></div>
                <div className="bg-orange-500 rounded-lg"></div>
                <div className="bg-red-700 rounded-lg"></div>
              </div>
            </div>
          </div>
          
        </div>
      </main>

      {/* How it works */}
      <section className="py-24 bg-gray-50 border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center mb-16">
            <span className="text-orange-600 font-bold tracking-widest text-xs uppercase mb-3 block">How it works</span>
            <h2 className="text-4xl md:text-5xl font-display font-extrabold text-gray-900">Adaptive by design.</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="card-panel card-panel-hover p-8">
              <div className="bg-red-50 text-red-600 w-12 h-12 rounded-2xl flex items-center justify-center mb-6">
                <Activity className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-4 font-display">Classify & route</h3>
              <p className="text-gray-500 leading-relaxed font-medium">
                Every event is tagged with a priority tier — Payment, Inventory, Click, or Log — and instantly routed to the right queue.
              </p>
            </div>
            
            <div className="card-panel card-panel-hover p-8 relative top-0 md:top-6">
              <div className="bg-yellow-50 text-yellow-600 w-12 h-12 rounded-2xl flex items-center justify-center mb-6">
                <Zap className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-4 font-display">Adapt under load</h3>
              <p className="text-gray-500 leading-relaxed font-medium">
                When Tier 1 latency rises, the system escalates through 4 levels: Normal → Elevated → Critical → Emergency, shedding lower-priority work.
              </p>
            </div>
            
            <div className="card-panel card-panel-hover p-8">
              <div className="bg-green-50 text-green-600 w-12 h-12 rounded-2xl flex items-center justify-center mb-6">
                <ShieldAlert className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-4 font-display">Never drop PO</h3>
              <p className="text-gray-500 leading-relaxed font-medium">
                Critical events (payments, orders) are guaranteed. The system enforces a hard invariant: zero PO events shed, regardless of load.
              </p>
            </div>
          </div>

        </div>
      </section>

      {/* Built for scale */}
      <section className="py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center mb-16">
            <span className="text-orange-600 font-bold tracking-widest text-xs uppercase mb-3 block">Built for Scale</span>
            <h2 className="text-4xl md:text-5xl font-display font-extrabold text-gray-900">The E-Commerce Flash Sale</h2>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
            
            <div>
              <h3 className="text-3xl font-display font-bold mb-6 leading-tight">
                When the spike hits, the pipeline doesn't panic. It does <span className="text-orange-600">jugaad</span>.
              </h3>
              <p className="text-gray-500 leading-relaxed font-medium mb-10">
                Imagine an e-commerce platform receiving a mixed event stream: orders, payments, inventory updates, user activity (clicks/views), and application logs.
              </p>

              <div className="space-y-6 mb-10">
                <div className="flex gap-4">
                  <div className="bg-green-50 text-green-600 w-10 h-10 rounded-full flex items-center justify-center shrink-0">
                    <Activity className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900">Normal Load</h4>
                    <p className="text-sm text-gray-500 font-medium">~1,000 events/minute handled comfortably.</p>
                  </div>
                </div>
                
                <div className="flex gap-4">
                  <div className="bg-red-50 text-red-600 w-10 h-10 rounded-full flex items-center justify-center shrink-0">
                    <Zap className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900">Flash Sale Spike</h4>
                    <p className="text-sm text-gray-500 font-medium">~20,000 events/minute — a sudden 20× surge.</p>
                  </div>
                </div>
              </div>

              <div className="bg-orange-50 border-l-4 border-orange-500 p-6 rounded-r-xl">
                <p className="text-gray-700 font-medium text-sm leading-relaxed">
                  <strong className="text-gray-900">The Core Philosophy:</strong> Not all events are equal. A payment failing to process is a business problem. A log line arriving 30 seconds late is fine. AdaptQ recognizes this difference and acts accordingly.
                </p>
              </div>
            </div>

            <div className="card-panel p-8 shadow-xl">
              <h4 className="font-bold text-xs tracking-widest text-gray-500 uppercase mb-8">Traffic Distribution</h4>
              
              <div className="space-y-6">
                <TrafficRow percentage="4%" name="Payment" tier="Tier 1" color="text-red-600" bg="bg-red-50" desc="Critical, never dropped" />
                <hr className="border-gray-100" />
                <TrafficRow percentage="9%" name="Order" tier="Tier 1" color="text-red-600" bg="bg-red-50" desc="Critical, never dropped" />
                <hr className="border-gray-100" />
                <TrafficRow percentage="13%" name="Inventory" tier="Tier 2" color="text-yellow-600" bg="bg-yellow-50" desc="Important, can batch/defer" />
                <hr className="border-gray-100" />
                <TrafficRow percentage="28%" name="Clicks" tier="Tier 3" color="text-green-600" bg="bg-green-50" desc="Useful, can defer/shed" />
                <hr className="border-gray-100" />
                <TrafficRow percentage="46%" name="Logs" tier="Tier 4" color="text-green-600" bg="bg-green-50" desc="Noise, shed freely under load" />
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* CTA section */}
      <section className="py-32 bg-[#fffbf0] border-t border-orange-100">
        <div className="max-w-3xl mx-auto text-center px-4">
          <div className="w-16 h-16 bg-yellow-100 text-yellow-600 rounded-full flex items-center justify-center mx-auto mb-8">
            <Activity className="w-8 h-8" />
          </div>
          <h2 className="text-5xl font-display font-extrabold text-gray-900 mb-6">See it in action.</h2>
          <p className="text-xl text-gray-500 font-medium mb-10">
            Trigger a 10× traffic spike and watch the pipeline self-adapt in real time without dropping a single payment.
          </p>
          <button className="bg-secondary hover:bg-yellow-400 text-black font-bold px-10 py-4 rounded-xl shadow-lg transition-transform hover:-translate-y-1">
            Launch Simulator
          </button>
        </div>
      </section>
      
    </div>
  );
}

function TrafficRow({ percentage, name, tier, color, bg, desc }: any) {
  return (
    <div className="flex items-center gap-6">
      <div className={`w-12 font-display font-bold text-lg ${color}`}>{percentage}</div>
      <div>
        <div className="flex items-center gap-2 mb-1">
          <span className="font-bold text-gray-900">{name}</span>
          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${bg} ${color}`}>{tier}</span>
        </div>
        <div className="text-xs text-gray-500 font-medium">{desc}</div>
      </div>
    </div>
  );
}
