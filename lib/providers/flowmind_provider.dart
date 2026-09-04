import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_state.dart';
import '../models/processing_decision.dart';
import 'pipeline_provider.dart';

final agentStateStreamProvider = StreamProvider<AgentStateSummary>((ref) {
  final realtime = ref.watch(pipelineRealtimeServiceProvider);
  return realtime.agentStateStream;
});

final decisionsStreamProvider = StreamProvider<List<ProcessingDecision>>((ref) {
  final realtime = ref.watch(pipelineRealtimeServiceProvider);
  return realtime.decisionsStream;
});
