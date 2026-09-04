import 'dart:async';
import 'dart:io';

// ANSI Color Codes
const String reset = '\x1B[0m';
const String bold = '\x1B[1m';
const String dim = '\x1B[2m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String magenta = '\x1B[35m';
const String cyan = '\x1B[36m';
const String white = '\x1B[37m';
const String orange = '\x1B[38;5;208m';

void printHeader() {
  print('''
$orange$bold
    _       _             _    ___  
   / \\   __| | __ _ _ __ | |_ / _ \\ 
  / _ \\ / _` |/ _` | '_ \\| __| | | |
 / ___ \\ (_| | (_| | |_) | |_| |_| |
/_/   \\_\\__,_|\\__,_| .__/ \\__|\\__\\_\\
                   |_|              
$reset$white$bold   ADAPTIVE AI DATA PIPELINE COMMAND CENTER$reset
$dim   "Process what matters. Defer what can wait."$reset
$dim   --------------------------------------------------------------$reset
''');
}

void printMeter(String lane, String name, int depth, int maxDepth, String mode, String color, String extra) {
  final int barWidth = 22;
  final double ratio = (depth / maxDepth).clamp(0.0, 1.0);
  final int filled = (ratio * barWidth).round();
  final int empty = barWidth - filled;
  final String bar = '█' * filled + '░' * empty;

  stdout.write('  $bold$color[$lane $name]$reset ');
  stdout.write('$color[$bar]$reset ');
  stdout.write('Depth: ${depth.toString().padLeft(4)} | ');
  stdout.write('Mode: ${mode.padRight(7)} | ');
  stdout.writeln(extra);
}

Future<void> sleepMs(int ms) => Future.delayed(Duration(milliseconds: ms));

Future<void> main() async {
  print('\x1B[2J\x1B[0;0H'); // Clear screen
  printHeader();

  print('$cyan[INIT]$reset Initializing AdaptQ pipeline runtime & FlowMind AI Agent...');
  await sleepMs(800);
  print('$green[READY]$reset Ingestion listener active. SafetyGuard rules verified (4 invariants).\n');
  await sleepMs(1000);

  // ==========================================
  // PHASE 1: BASELINE TRAFFIC
  // ==========================================
  print('$bold$white==============================================================$reset');
  print('$bold$white  PHASE 1: BASELINE NORMAL TRAFFIC (~1,000 events/min)$reset');
  print('$bold$white==============================================================$reset');
  print('$dim  All workloads streaming direct to workers. Queue load minimal.$reset\n');

  for (int i = 1; i <= 3; i++) {
    stdout.write('\r$dim  [T+${i}s]$reset Ingestion: ${1000 + i * 15} e/min | System Load: 14% | Status: $green$bold HEALTHY $reset');
    await sleepMs(800);
  }
  print('\n');

  printMeter('P0', 'PAYMENT ', 12, 500, 'STREAM', green, 'SLA: 100% | Latency: 18ms | Drops: 0');
  printMeter('P1', 'INVENTRY', 45, 1000, 'STREAM', cyan, 'SLA: 100% | Latency: 42ms | Drops: 0');
  printMeter('P2', 'ACTIVITY', 120, 2000, 'STREAM', blue, 'SLA: 100% | Latency: 98ms | Drops: 0');
  printMeter('P3', 'APP LOGS', 340, 5000, 'STREAM', white, 'SLA: BestEffort  | Drops: 0');

  print('\n$dim  Simulating flash surge...$reset');
  await sleepMs(1800);

  // ==========================================
  // PHASE 2: 20x FLASH SURGE ATTACK
  // ==========================================
  print('\n$bold$red==============================================================$reset');
  print('$bold$red  PHASE 2: ⚠️  INJECTING 20× FLASH TRAFFIC SURGE!$reset');
  print('$bold$red==============================================================$reset');
  print('$yellow$bold  TRAFFIC EXPLOSION: 1,000 -> 20,000 events/minute (Flash Sale Surge)$reset\n');
  await sleepMs(600);

  for (int pct = 20; pct <= 100; pct += 20) {
    stdout.write('\r  $red[SURGE INGESTION]$reset Traffic Rate: ${(pct * 200)} e/min | Queue Pressure: ${pct}%');
    await sleepMs(300);
  }
  print('\n');

  printMeter('P0', 'PAYMENT ', 420, 500, 'STREAM', red, 'PRESSURE CRITICAL | Latency: 220ms');
  printMeter('P1', 'INVENTRY', 910, 1000, 'STREAM', red, 'QUEUE NEAR CAPACITY');
  printMeter('P2', 'ACTIVITY', 1850, 2000, 'STREAM', red, 'SATURATED (Buffer overflowing)');
  printMeter('P3', 'APP LOGS', 4820, 5000, 'STREAM', red, 'HEAD-OF-LINE BLOCKING RISK!');

  print('\n$red$bold  ⚠️  TRADITIONAL FIFO PIPELINES CRASH HERE (42% payments dropped).$reset');
  print('$dim  Evaluating AdaptQ autonomous response...$reset\n');
  await sleepMs(1500);

  // ==========================================
  // PHASE 3: FLOWMIND AI CONTROL LOOP
  // ==========================================
  print('$bold$magenta==============================================================$reset');
  print('$bold$magenta  PHASE 3: FLOWMIND AI AGENT AUTONOMOUS CONTROL LOOP$reset');
  print('$bold$magenta==============================================================$reset');

  print('  $magenta$bold[OBSERVE]$reset Traffic: 20,000 e/min | Queue Pressure: 94% | P0 Latency: 220ms');
  await sleepMs(700);
  print('  $magenta$bold[ANALYZE]$reset Worker saturation detected. P0 Payment stream threatened by P3 Log flooding.');
  await sleepMs(700);
  print('  $magenta$bold[PROPOSE]$reset Formulating Multi-Tiered Mitigation Policy:');
  print('           • P0 Payments : Lock 100% Streaming (0 shedding, highest priority)');
  print('           • P1 Inventory: Adaptive Batching (Batch size: 500)');
  print('           • P2 Activity : Intelligent Deferral (30-sec deferral window)');
  print('           • P3 App Logs : Controlled Load Shedding (75% shed, 25% retained sample)');
  await sleepMs(900);

  print('\n$bold$yellow  [SAFETY GUARD] Deterministic Invariant Check:$reset');
  await sleepMs(400);
  print('    $green✓$reset Rule 1: P0 Payment and Order Shedding Prohibition -> $green$bold PASSED (Immutable)$reset');
  await sleepMs(300);
  print('    $green✓$reset Rule 2: Max Batch Size Ceiling (500 <= 1000)       -> $green$bold PASSED$reset');
  await sleepMs(300);
  print('    $green✓$reset Rule 3: Max Deferral Window (30s <= 60s)           -> $green$bold PASSED$reset');
  await sleepMs(300);
  print('    $green✓$reset Rule 4: Max Shedding Ceiling (75% <= 90%)          -> $green$bold PASSED$reset');
  await sleepMs(500);
  print('  $green$bold[EXECUTE]$reset Policy approved by SafetyGuard. Hot-swapping runtime without restart!\n');
  await sleepMs(1200);

  // ==========================================
  // PHASE 4: TRIAGE MITIGATION ACTIVE
  // ==========================================
  print('$bold$orange==============================================================$reset');
  print('$bold$orange  PHASE 4: REAL-TIME MITIGATION UNDER 20,000 e/min SURGE$reset');
  print('$bold$orange==============================================================$reset');
  print('$dim  Workload prioritization enforced. Sinks protected.$reset\n');

  printMeter('P0', 'PAYMENT ', 16, 500, 'STREAM', green, '$bold 100% PROTECTED | Latency: 48ms | Drops: 0 $reset');
  printMeter('P1', 'INVENTRY', 190, 1000, 'BATCH', orange, 'Batch size: 500 | Throughput: 4.5x');
  printMeter('P2', 'ACTIVITY', 450, 2000, 'DEFER', blue, 'Deferred to spillover disk (30s window)');
  printMeter('P3', 'APP LOGS', 85, 5000, 'SHED', yellow, '75% Shed | 25% Sample preserved');

  print('\n  $green$bold✓ Critical Shield Status: ZERO P0 Payments or Orders Lost!$reset');
  print('  $cyan$bold✓ P0 Payment Latency stabilized at 48 ms (Target < 50 ms)$reset\n');
  await sleepMs(2000);

  // ==========================================
  // PHASE 5: RECOVERY & DRAINING
  // ==========================================
  print('$bold$cyan==============================================================$reset');
  print('$bold$cyan  PHASE 5: TRAFFIC NORMALIZATION & QUEUE RECOVERY$reset');
  print('$bold$cyan==============================================================$reset');
  print('  Traffic normalizing to 1,000 e/min...');
  for (int i = 3; i >= 1; i--) {
    stdout.write('\r  Draining deferred P2 queues into active workers... [${(4 - i) * 33}% completed]');
    await sleepMs(700);
  }
  print('\n  $green$bold✓ All deferred queues drained. Streaming defaults safely restored.$reset\n');
  await sleepMs(1000);

  // ==========================================
  // PHASE 6: BENCHMARK SCORECARD
  // ==========================================
  print('$bold$white==============================================================$reset');
  print('$bold$white  PHASE 6: NAIVE PIPELINE VS ADAPTQ BENCHMARK SCORECARD$reset');
  print('$bold$white==============================================================$reset');

  print('''
$white┌───────────────────────────────┬──────────────────────┬──────────────────────┐
│ $bold${'METRIC'.padRight(29)}$reset$white │ $bold${red}${'NAIVE FIFO PIPELINE'.padRight(20)}$reset$white │ $bold${green}${'ADAPTQ AI PIPELINE'.padRight(20)}$reset$white │
├───────────────────────────────┼──────────────────────┼──────────────────────┤
│ Critical P0 Events Lost       │ $red${'4,281 (42% DROPPED)'.padRight(20)}$reset$white │ $green$bold${'0 (100% PROTECTED)'.padRight(20)}$reset$white │
│ P0 Payment Latency            │ $red${'2,840 ms (TIMEOUT)'.padRight(20)}$reset$white │ $green$bold${'48 ms (HEALTHY)'.padRight(20)}$reset$white │
│ Priority Isolation            │ ${'None (FIFO Blocking)'.padRight(20)} │ $cyan${'P0-P3 Tiered Matrix'.padRight(20)}$reset$white │
│ Dynamic Batch Sizing          │ ${'Disabled (Fixed 1)'.padRight(20)} │ $orange${'Adaptive (250-500)'.padRight(20)}$reset$white │
│ Autonomous MTTR               │ $red${'18-35 min (Manual)'.padRight(20)}$reset$white │ $green$bold${'< 3 seconds'.padRight(20)}$reset$white │
│ Safety Guardrails             │ ${'None'.padRight(20)} │ $green${'Deterministic Rails'.padRight(20)}$reset$white │
└───────────────────────────────┴──────────────────────┴──────────────────────┘$reset
''');

  print('$green$bold[COMPLETE] AdaptQ demo finished successfully.$reset');
  print('$dim Run again anytime with: dart run scripts/demo.dart or .\\scripts\\demo.ps1$reset\n');
}
