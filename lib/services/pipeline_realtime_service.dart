import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/event.dart';
import '../models/processing_decision.dart';
import '../models/agent_state.dart';

abstract class PipelineRealtimeService {
  Stream<PipelineMetrics> get metricsStream;
  Stream<List<PriorityQueueMetrics>> get queuesStream;
  Stream<List<PipelineEvent>> get eventsStream;
  Stream<List<ProcessingDecision>> get decisionsStream;
  Stream<AgentStateSummary> get agentStateStream;

  void dispose();
}
