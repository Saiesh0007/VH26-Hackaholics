import 'dart:async';
import 'pipeline_runtime.dart';
import '../agent/flowmind_agent.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/event.dart';
import '../models/processing_decision.dart';
import '../models/agent_state.dart';
import '../models/incident.dart';
import '../models/simulation_config.dart';
import '../services/bland_ai_service.dart';

class SimulationEngine {
  final PipelineRuntime runtime = PipelineRuntime();
  final FlowMindAgent agent = FlowMindAgent();
  
  SimulationConfig _config = SimulationConfig.defaultConfig();
  Timer? _tickTimer;
  bool _isRunning = false;

  final StreamController<PipelineMetrics> _metricsController = StreamController<PipelineMetrics>.broadcast();
  final StreamController<List<PriorityQueueMetrics>> _queuesController = StreamController<List<PriorityQueueMetrics>>.broadcast();
  final StreamController<List<PipelineEvent>> _eventsController = StreamController<List<PipelineEvent>>.broadcast();
  final StreamController<List<ProcessingDecision>> _decisionsController = StreamController<List<ProcessingDecision>>.broadcast();
  final StreamController<AgentStateSummary> _agentStateController = StreamController<AgentStateSummary>.broadcast();

  final List<SystemIncident> _incidents = [];

  Stream<PipelineMetrics> get metricsStream => _metricsController.stream;
  Stream<List<PriorityQueueMetrics>> get queuesStream => _queuesController.stream;
  Stream<List<PipelineEvent>> get eventsStream => _eventsController.stream;
  Stream<List<ProcessingDecision>> get decisionsStream => _decisionsController.stream;
  Stream<AgentStateSummary> get agentStateStream => _agentStateController.stream;
  List<SystemIncident> get incidents => List.unmodifiable(_incidents);

  bool get isRunning => _isRunning;

  SimulationEngine() {
    startSimulation();
  }

  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
    _tick();
  }

  void stopSimulation() {
    _tickTimer?.cancel();
    _isRunning = false;
  }

  void updateConfig(SimulationConfig config) {
    _config = config;
    runtime.setTrafficRate(config.baselineTrafficRate);
  }

  void trigger20xSpike() {
    runtime.setTrafficRate(20000);
    _incidents.insert(
      0,
      SystemIncident(
        id: 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: '🔥 20× TRAFFIC SPIKE DETECTED',
        description: 'Traffic surged from 1,000 to 20,000 events/min.',
        severity: IncidentSeverity.critical,
        timestamp: DateTime.now(),
        status: 'ACTIVE',
      ),
    );
  }

  void triggerEdgeCase() {
    setTrafficRate(100000);
  }

  void setTrafficRate(int rate) {
    runtime.setTrafficRate(rate);
    if (rate > 1000) {
      final mult = (rate / 1000).round();
      final isEdgeCase = rate >= 80000;
      _incidents.insert(
        0,
        SystemIncident(
          id: 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          title: isEdgeCase ? '🚨 UNRECOVERABLE EDGE CASE ($rate e/min)' : '🔥 ${mult}× TRAFFIC SURGE ($rate e/min)',
          description: isEdgeCase
              ? 'Extreme stress traffic surge. Evaluator Agent escalating to Bland AI SRE dispatch.'
              : 'Traffic adjusted dynamically to $rate events/min.',
          severity: rate >= 40000 ? IncidentSeverity.critical : IncidentSeverity.warning,
          timestamp: DateTime.now(),
          status: 'ACTIVE',
        ),
      );

      // If extreme stress edge case, automatically trigger Bland AI call!
      if (isEdgeCase) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          BlandAiService().triggerEmergencyCall(
            incidentTitle: 'CRITICAL ${rate ~/ 1000}× TRAFFIC SURGE ($rate e/min)',
            reason: 'Traffic rate reached $rate e/min exceeding autonomous mitigation thresholds. P0 payment latency at risk. Escalating to SRE engineer.',
            p0LatencyMs: 148.5,
            trafficRate: rate,
          );
        });
      }
    } else {
      recoverToNormal();
    }
  }

  void recoverToNormal() {
    runtime.setTrafficRate(1000);
    _incidents.insert(
      0,
      SystemIncident(
        id: 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: '🟢 TRAFFIC RECOVERY INITIATED',
        description: 'Traffic normalized to baseline (1,000 events/min). Draining queues.',
        severity: IncidentSeverity.info,
        timestamp: DateTime.now(),
        status: 'RESOLVED',
      ),
    );
  }

  void _tick() {
    // 1. Run Pipeline Runtime tick
    final metrics = runtime.tickSimulation();
    final queues = runtime.getQueueMetricsList(metrics);

    // 2. FlowMind Agent evaluates metrics and modifies policy if needed
    agent.runControlLoop(runtime, metrics);

    // 3. Emit streams
    _metricsController.add(metrics);
    _queuesController.add(queues);
    _eventsController.add(runtime.recentEvents);
    _decisionsController.add(agent.decisionsHistory);
    _agentStateController.add(agent.summary);
  }

  void dispose() {
    stopSimulation();
    _metricsController.close();
    _queuesController.close();
    _eventsController.close();
    _decisionsController.close();
    _agentStateController.close();
  }
}
