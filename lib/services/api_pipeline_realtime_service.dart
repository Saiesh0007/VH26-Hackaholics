import 'dart:async';
import '../models/agent_state.dart';
import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/processing_decision.dart';
import '../models/queue_metrics.dart';
import '../repositories/api_pipeline_repository.dart';
import 'pipeline_realtime_service.dart';

class ApiPipelineRealtimeService implements PipelineRealtimeService {
  final ApiPipelineRepository repository;
  final _metricsController = StreamController<PipelineMetrics>.broadcast();
  final _queuesController =
      StreamController<List<PriorityQueueMetrics>>.broadcast();
  final _eventsController = StreamController<List<PipelineEvent>>.broadcast();
  final _decisionsController =
      StreamController<List<ProcessingDecision>>.broadcast();
  final _agentStateController = StreamController<AgentStateSummary>.broadcast();
  Timer? _timer;

  ApiPipelineRealtimeService(this.repository) {
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      _metricsController.add(await repository.getMetrics());
    } catch (_) {
      _metricsController.add(PipelineMetrics.initial());
    }
    _queuesController.add(const []);
    _eventsController.add(const []);
    _decisionsController.add(const []);
    _agentStateController.add(AgentStateSummary.initial());
  }

  @override
  Stream<PipelineMetrics> get metricsStream => _metricsController.stream;

  @override
  Stream<List<PriorityQueueMetrics>> get queuesStream =>
      _queuesController.stream;

  @override
  Stream<List<PipelineEvent>> get eventsStream => _eventsController.stream;

  @override
  Stream<List<ProcessingDecision>> get decisionsStream =>
      _decisionsController.stream;

  @override
  Stream<AgentStateSummary> get agentStateStream =>
      _agentStateController.stream;

  @override
  void dispose() {
    _timer?.cancel();
    _metricsController.close();
    _queuesController.close();
    _eventsController.close();
    _decisionsController.close();
    _agentStateController.close();
  }
}
