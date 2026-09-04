import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import 'pipeline_provider.dart';

final metricsStreamProvider = StreamProvider<PipelineMetrics>((ref) {
  final realtime = ref.watch(pipelineRealtimeServiceProvider);
  return realtime.metricsStream;
});

final queuesStreamProvider = StreamProvider<List<PriorityQueueMetrics>>((ref) {
  final realtime = ref.watch(pipelineRealtimeServiceProvider);
  return realtime.queuesStream;
});
