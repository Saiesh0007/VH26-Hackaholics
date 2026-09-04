import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import 'pipeline_provider.dart';

final eventsStreamProvider = StreamProvider<List<PipelineEvent>>((ref) {
  final realtime = ref.watch(pipelineRealtimeServiceProvider);
  return realtime.eventsStream;
});

final selectedEventProvider = StateProvider<PipelineEvent?>((ref) => null);
final priorityFilterProvider = StateProvider<WorkloadPriority?>((ref) => null);
final strategyFilterProvider = StateProvider<ProcessingStrategy?>((ref) => null);
